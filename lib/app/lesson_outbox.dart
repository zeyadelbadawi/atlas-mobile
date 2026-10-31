import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_error.dart';
import '../core/clock.dart';
import 'learning_providers.dart';
import 'providers.dart';

/// "Lesson done" and its undo, pressed while the connection dropped.
@immutable
class LessonOp {
  const LessonOp({
    required this.courseId,
    required this.lessonId,
    required this.complete,
    required this.opId,
    required this.at,
  });

  factory LessonOp.fromJson(Map<String, dynamic> j) => LessonOp(
    courseId: j['courseId'] as String,
    lessonId: j['lessonId'] as String,
    complete: j['complete'] == true,
    opId: j['opId'] as String,
    at: (j['at'] as num).toInt(),
  );

  final String courseId;
  final String lessonId;

  /// True: marked done. False: taken back.
  final bool complete;

  /// Reused on every retry, so the server sees one operation.
  final String opId;

  /// When the learner pressed it (epoch ms): the server keeps the newest
  /// per lesson, so a late one never overwrites a later choice made on
  /// another device.
  final int at;

  Map<String, Object> toJson() => {
    'courseId': courseId,
    'lessonId': lessonId,
    'complete': complete,
    'opId': opId,
    'at': at,
  };
}

enum LessonOpResult { sent, queued }

/// The app's side of the website's learner outbox: a lesson marked done (or
/// taken back) without a connection is kept on the phone and sent when the
/// connection returns, oldest first, with the same ordering stamps the
/// website uses. Per account and academy, for up to a week.
///
/// Quiz answers and assignment submissions are not queued: a quiz belongs
/// to the server's clock, and a submission waits for the learner to send
/// it again (its draft is already kept).
class LessonOutbox extends Notifier<List<LessonOp>> {
  static const maxAge = Duration(days: 7);
  static const _retries = [10, 30, 60, 120, 300];

  Timer? _retry;
  int _attempt = 0;
  bool _flushing = false;
  String? _storeKey;

  @override
  List<LessonOp> build() {
    final key = _storeKey = _key();
    ref.onDispose(() => _retry?.cancel());
    if (key == null) return const [];
    final life = AppLifecycleListener(onResume: () => unawaited(flush()));
    ref.onDispose(life.dispose);
    final raw = ref.read(sharedPreferencesProvider).getString(key);
    final ops = <LessonOp>[];
    if (raw != null) {
      try {
        for (final m in (jsonDecode(raw) as List).whereType<Map>()) {
          ops.add(LessonOp.fromJson(Map<String, dynamic>.from(m)));
        }
      } on Object {
        // A damaged queue is dropped rather than crashing the app.
      }
    }
    if (ops.isNotEmpty) scheduleMicrotask(() => unawaited(flush()));
    return ops;
  }

  /// The signed-in account in this academy; the queue is rebuilt (and
  /// another account's left alone) when it changes.
  String? _key() {
    final s = ref.watch(
      sessionProvider.select(
        (s) => s.status == SessionStatus.signedIn
            ? (s.academy?.id, s.user?['id'])
            : null,
      ),
    );
    if (s == null || s.$1 == null || s.$2 == null) return null;
    return 'outbox.lessons.${s.$1}.${s.$2}';
  }

  /// Whether [lessonId] has a choice still waiting to be sent.
  LessonOp? pendingFor(String lessonId) =>
      state.where((o) => o.lessonId == lessonId).lastOrNull;

  Future<LessonOpResult> complete(String courseId, String lessonId) =>
      _do(courseId, lessonId, complete: true);

  Future<LessonOpResult> undo(String courseId, String lessonId) =>
      _do(courseId, lessonId, complete: false);

  /// Sends now; when the connection is the problem, queues it instead.
  /// Any other refusal is thrown, as before.
  Future<LessonOpResult> _do(
    String courseId,
    String lessonId, {
    required bool complete,
  }) async {
    final op = LessonOp(
      courseId: courseId,
      lessonId: lessonId,
      complete: complete,
      opId: _newOpId(),
      at: clockNow().millisecondsSinceEpoch,
    );
    // An older choice for this lesson that has not left yet: this one
    // replaces it (only the newest matters, and order must hold).
    if (pendingFor(lessonId) != null) {
      await _save([...state.where((o) => o.lessonId != lessonId), op]);
      unawaited(flush());
      return LessonOpResult.queued;
    }
    try {
      await _send(op);
      return LessonOpResult.sent;
    } on AtlasApiException catch (e) {
      if (!_isConnection(e)) rethrow;
      await _save([...state, op]);
      _scheduleRetry();
      return LessonOpResult.queued;
    }
  }

  Future<void> _send(LessonOp op) {
    final repo = ref.read(learningRepositoryProvider);
    return op.complete
        ? repo.completeLesson(
            op.courseId,
            op.lessonId,
            opId: op.opId,
            clientOpAt: op.at,
          )
        : repo.undoCompleteLesson(
            op.courseId,
            op.lessonId,
            opId: op.opId,
            clientOpAt: op.at,
          );
  }

  /// No answer from the server (no network, a timeout) or a server error
  /// worth trying again.
  static bool _isConnection(AtlasApiException e) =>
      e.kind == 'network' ||
      e.kind == 'timeout' ||
      (e.status != null && e.status! >= 500);

  /// Sends what is waiting, oldest first; stops at the first connection
  /// failure and tries again later.
  Future<void> flush() async {
    if (_flushing || state.isEmpty) return;
    _flushing = true;
    _retry?.cancel();
    final touched = <String>{};
    try {
      final cutoff = clockNow().subtract(maxAge).millisecondsSinceEpoch;
      for (final op in [...state]) {
        if (op.at < cutoff) {
          await _save(state.where((o) => o.opId != op.opId).toList());
          continue;
        }
        try {
          // An older stamp than the server's answers `applied: false`:
          // another device acted since. Done either way.
          await _send(op);
        } on AtlasApiException catch (e) {
          if (_isConnection(e)) {
            _scheduleRetry();
            return;
          }
          // Refused for good (the lesson is gone, the enrolment ended, the
          // lesson must be watched first): nothing left to send.
        }
        touched.add(op.courseId);
        await _save(state.where((o) => o.opId != op.opId).toList());
      }
      _attempt = 0;
    } finally {
      _flushing = false;
      for (final courseId in touched) {
        refreshCourse(ref, courseId);
      }
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final seconds = _retries[min(_attempt, _retries.length - 1)];
    _attempt++;
    _retry = Timer(Duration(seconds: seconds), () => unawaited(flush()));
  }

  Future<void> _save(List<LessonOp> ops) async {
    state = List.unmodifiable(ops);
    final key = _storeKey;
    if (key == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    ops.isEmpty
        ? await prefs.remove(key)
        : await prefs.setString(
            key,
            jsonEncode([for (final o in ops) o.toJson()]),
          );
  }

  /// 32 hex characters (the server accepts `[A-Za-z0-9_-]{8,100}`).
  static String _newOpId() {
    final r = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

final lessonOutboxProvider = NotifierProvider<LessonOutbox, List<LessonOp>>(
  LessonOutbox.new,
);
