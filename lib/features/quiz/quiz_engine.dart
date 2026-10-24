// The attempt's moving parts, kept free of widgets so the behaviour a
// learner depends on (what counts as answered, when the clock warns, that a
// save is never lost or doubled) is unit-tested with fake time.
//
// Ported from the web (atlas/src/features/learner: quiz-attempt.utils,
// useQuizAutosave, useQuizIntegrity) so both clients follow one contract.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_error.dart';
import '../../core/learning/assessment_models.dart';

/// Debounce between the last edit and the autosave request.
const autosaveDebounce = Duration(milliseconds: 1500);

/// Countdown announcements (10 min, 5 min, 1 min, 30 s), each once.
const countdownAnnouncements = [600, 300, 60, 30];

/// Message keys meaning "this attempt no longer accepts answers".
const terminalAttemptKeys = {
  'errors.quiz.attemptExpired',
  'errors.quiz.attemptAlreadySubmitted',
  'errors.quiz.attemptInvalidated',
};

bool isTerminalAttemptError(Object e) =>
    e is AtlasApiException && terminalAttemptKeys.contains(e.messageKey);

typedef AnswerMap = Map<String, QuizAnswer>;

AnswerMap toAnswerMap(Iterable<QuizAnswer> answers) => {
  for (final a in answers) a.questionId: a,
};

/// Answers in the attempt's question order, blanks left out — the wire shape.
List<QuizAnswer> toAnswerList(
  List<QuizSessionQuestion> questions,
  AnswerMap answers,
) => [
  for (final q in questions)
    if (answers[q.id]?.isAnswered ?? false) answers[q.id]!,
];

int answeredCount(List<QuizSessionQuestion> questions, AnswerMap answers) =>
    questions.where((q) => answers[q.id]?.isAnswered ?? false).length;

/// 1-based numbers of the questions still unanswered.
List<int> unansweredNumbers(
  List<QuizSessionQuestion> questions,
  AnswerMap answers,
) => [
  for (var i = 0; i < questions.length; i++)
    if (!(answers[questions[i].id]?.isAnswered ?? false)) i + 1,
];

/// Merges the learner's unconfirmed edits onto the server's newer copy: a
/// question changed since [baseline] (the last confirmed answers) keeps the
/// learner's answer, every other one takes the server's.
List<QuizAnswer> rebaseAnswers(
  List<QuizAnswer>? server,
  List<QuizAnswer> local,
  List<QuizAnswer> baseline,
) {
  if (server == null) return [...local];
  final s = toAnswerMap(server), l = toAnswerMap(local);
  final b = toAnswerMap(baseline);
  final ids = {...l.keys, ...s.keys, ...b.keys};
  return [for (final id in ids) ?(_edited(l[id], b[id]) ? l[id] : s[id])];
}

bool _edited(QuizAnswer? local, QuizAnswer? base) {
  if (local == null && base == null) return false;
  if (local == null || base == null) return true;
  return !local.sameAs(base);
}

/// The server's clock, measured when a response arrived: remaining time is
/// derived from the server's `serverNow` and `deadlineAt` plus the phone's
/// monotonic stopwatch, never from the phone's wall clock alone.
class AttemptClock {
  AttemptClock({required String? serverNow, required String? deadlineAt}) {
    sync(serverNow: serverNow, deadlineAt: deadlineAt);
  }

  final _watch = Stopwatch()..start();
  DateTime? _serverAtSync;
  Duration _syncedAt = Duration.zero;
  DateTime? deadline;

  void sync({required String? serverNow, required String? deadlineAt}) {
    _serverAtSync = serverNow == null ? null : DateTime.tryParse(serverNow);
    _syncedAt = _watch.elapsed;
    deadline = deadlineAt == null ? null : DateTime.tryParse(deadlineAt);
  }

  /// Seconds left as the server sees it; null for an untimed attempt.
  int? remaining() {
    final d = deadline;
    if (d == null) return null;
    final now = (_serverAtSync ?? DateTime.now().toUtc()).add(
      _watch.elapsed - _syncedAt,
    );
    final ms = d.difference(now).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }
}

/// `12:30` / `1:05:20`.
String formatCountdown(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(r)}' : '$m:${two(r)}';
}

/// The announcement the countdown just crossed, if any (fires once, even
/// when a paused app skipped several seconds).
int? crossedAnnouncement(int? previous, int? current) {
  if (previous == null || current == null) return null;
  for (final t in countdownAnnouncements) {
    if (previous > t && current <= t) return t;
  }
  return null;
}

bool isUrgent(int? seconds) => seconds != null && seconds <= 120;

enum AutosaveState { idle, dirty, saving, saved, offline }

typedef SaveAnswers = Future<SaveAnswersResult> Function(
  int revision,
  List<QuizAnswer> answers,
);

/// The save queue behind "Saved just now".
///
/// One request in flight; every save carries a higher revision. An edit made
/// while a save is in flight goes out as soon as it returns. A failed save
/// is retried with backoff and the learner keeps answering. A stale save
/// (`applied: false`) is rebased onto the server's newer copy, never
/// dropped. A refusal saying the attempt is over stops the queue.
class QuizAutosave {
  QuizAutosave({
    required this.save,
    required int initialRevision,
    required List<QuizAnswer> confirmed,
    this.onSaved,
    this.onTerminal,
    this.onRebased,
  }) : _revision = initialRevision,
       _baseline = confirmed;

  final SaveAnswers save;
  final void Function(SaveAnswersResult)? onSaved;
  final VoidCallback? onTerminal;
  final void Function(List<QuizAnswer>)? onRebased;

  static const maxRebases = 3;
  static const retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
  ];

  final state = ValueNotifier(AutosaveState.idle);
  DateTime? lastSavedAt;

  int _revision;
  List<QuizAnswer> _baseline;
  List<QuizAnswer>? _pending;
  Future<void>? _inFlight;
  Timer? _debounce, _retry;
  int _failures = 0, _rebases = 0;
  bool _stopped = false;

  /// The revision the next save — and the submit — carries.
  int get nextRevision => _revision + 1;
  bool get stopped => _stopped;

  void schedule(List<QuizAnswer> answers) {
    if (_stopped) return;
    _pending = answers;
    state.value = AutosaveState.dirty;
    _debounce?.cancel();
    _debounce = Timer(autosaveDebounce, () {
      _debounce = null;
      unawaited(_send());
    });
  }

  /// Sends whatever is pending now; completes when nothing is in flight.
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    _retry?.cancel();
    _retry = null;
    await _send();
    while (_inFlight != null) {
      await _inFlight;
    }
  }

  Future<void> _send() {
    final running = _inFlight;
    if (running != null) return running;
    final answers = _pending;
    if (answers == null || _stopped) return Future.value();
    _pending = null;
    final revision = _revision + 1;
    state.value = AutosaveState.saving;
    final run = _run(answers, revision);
    _inFlight = run;
    return run;
  }

  Future<void> _run(List<QuizAnswer> answers, int revision) async {
    try {
      final r = await save(revision, answers);
      if (r.revision > _revision) _revision = r.revision;
      _failures = 0;
      if (!r.applied) {
        _rebases++;
        final merged = rebaseAnswers(r.answers, _pending ?? answers, _baseline);
        if (r.answers != null) _baseline = r.answers!;
        _pending = merged;
        onRebased?.call(merged);
        if (_rebases > maxRebases) throw StateError('rebase limit');
        state.value = AutosaveState.dirty;
        return;
      }
      _rebases = 0;
      _baseline = answers;
      lastSavedAt = r.savedAt ?? DateTime.now();
      onSaved?.call(r);
      state.value = _pending != null
          ? AutosaveState.dirty
          : AutosaveState.saved;
    } on Object catch (e) {
      if (isTerminalAttemptError(e)) {
        _stopped = true;
        _pending = null;
        state.value = AutosaveState.saved;
        onTerminal?.call();
        return;
      }
      _pending ??= answers;
      _failures++;
      state.value = AutosaveState.offline;
      final delay =
          retryDelays[(_failures - 1).clamp(0, retryDelays.length - 1)];
      _retry = Timer(delay, () {
        _retry = null;
        unawaited(_send());
      });
    } finally {
      _inFlight = null;
      if (_pending != null && !_stopped && _retry == null) {
        unawaited(_send());
      }
    }
  }

  void dispose() {
    _debounce?.cancel();
    _retry?.cancel();
    state.dispose();
  }
}

typedef RecordEvents = Future<EventsResult> Function(
  List<Map<String, Object?>> events,
);

/// The integrity record. Batches the events the academy chose to record and
/// sends them with the phone's timestamps; the SERVER decides what counts
/// and answers with the action the attempt needs. Nothing is blocked here.
///
/// On a phone the app is the whole screen, so the honest events are: the
/// attempt opened full screen, the learner left the app and came back, and
/// a connection check once a minute.
class QuizIntegrity {
  QuizIntegrity({
    required this.record,
    required this.mode,
    this.onWarn,
    this.onAutoSubmitted,
    this.flushEvery = const Duration(seconds: 2),
    this.heartbeatEvery = const Duration(minutes: 1),
  });

  final RecordEvents record;
  final String mode;
  final void Function(int violations, int max)? onWarn;
  final VoidCallback? onAutoSubmitted;
  final Duration flushEvery, heartbeatEvery;

  static const maxBatch = 50;

  final _queue = <Map<String, Object?>>[];
  Timer? _flushTimer, _heartbeat;
  bool _flushing = false, _stopped = false;
  int violationCount = 0;

  bool get active => mode != 'off';

  void start() {
    if (!active) return;
    _flushTimer = Timer.periodic(flushEvery, (_) => unawaited(flush()));
    _heartbeat = Timer.periodic(heartbeatEvery, (_) => push('heartbeat'));
    push('fullscreen_enter');
  }

  void push(String type) {
    if (!active || _stopped) return;
    _queue.add({
      'type': type,
      'clientAt': DateTime.now().toUtc().toIso8601String(),
    });
    // A backgrounded app may be suspended: send at once so the time is true.
    if (type == 'visibility_hidden') unawaited(flush());
  }

  void acknowledgeWarning() {
    push('warning_acknowledged');
    unawaited(flush());
  }

  Future<void> flush() async {
    if (_flushing || _stopped || _queue.isEmpty) return;
    final n = _queue.length < maxBatch ? _queue.length : maxBatch;
    final batch = _queue.sublist(0, n);
    _queue.removeRange(0, n);
    _flushing = true;
    try {
      final r = await record(batch);
      violationCount = r.violationCount;
      if (r.action == 'auto_submit') {
        _stopped = true;
        onAutoSubmitted?.call();
      } else if (r.action == 'warn') {
        onWarn?.call(r.violationCount, r.maxViolations);
      }
    } on Object {
      // Events are evidence, not answers: keep them for one more try.
      if (_queue.length < maxBatch) _queue.insertAll(0, batch);
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _heartbeat?.cancel();
    unawaited(flush());
    _stopped = true;
  }
}
