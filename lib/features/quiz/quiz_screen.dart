import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/push.dart';
import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import 'assessment_widgets.dart';
import 'quiz_engine.dart';
import 'quiz_results.dart';
import 'quiz_runner.dart';

/// A quiz: intro → running → results, and back to the intro for a retake.
///
/// Which state is decided from the server's attempt list, never from memory:
/// an open attempt means running (reopening the app resumes it with the
/// saved answers and the remaining time); a finished latest attempt means
/// results until the learner asks to retake.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.courseId, required this.quizId});
  final String courseId;
  final String quizId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

enum _Phase { loading, error, intro, running, results }

class _QuizScreenState extends ConsumerState<QuizScreen> {
  _Phase _phase = _Phase.loading;
  Object? _error;
  Quiz? _quiz;
  List<QuizAttempt> _attempts = const [];
  QuizSession? _session;
  QuizResults? _results;
  bool _starting = false;
  String? _startError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool intro = false}) async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    final repo = ref.read(assessmentRepositoryProvider);
    try {
      final both = await Future.wait<Object>([
        repo.quiz(widget.courseId, widget.quizId),
        repo.attempts(widget.courseId, widget.quizId),
      ]);
      _quiz = both[0] as Quiz;
      final attempts = _attempts = both[1] as List<QuizAttempt>;
      final latest = attempts.firstOrNull;
      if (latest != null && latest.isOpen) {
        await _openSession(latest.id);
      } else if (latest != null && !intro) {
        await _showResults(latest.id);
      } else {
        if (mounted) setState(() => _phase = _Phase.intro);
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _openSession(String attemptId) async {
    final repo = ref.read(assessmentRepositoryProvider);
    try {
      final s = await repo.session(widget.courseId, widget.quizId, attemptId);
      if (s.status != 'in_progress') return await _showResults(attemptId);
      if (!mounted) return;
      setState(() {
        _session = s;
        _phase = _Phase.running;
      });
    } on Object catch (e) {
      // Finalised on the server while the app was away: that is results.
      if (isTerminalAttemptError(e)) return _showResults(attemptId);
      rethrow;
    }
  }

  Future<void> _showResults(String attemptId) async {
    final repo = ref.read(assessmentRepositoryProvider);
    final r = await repo.results(widget.courseId, widget.quizId, attemptId);
    if (!mounted) return;
    setState(() {
      _results = r;
      _session = null;
      _phase = _Phase.results;
    });
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final attempt = await ref
          .read(assessmentRepositoryProvider)
          .start(widget.courseId, widget.quizId);
      await _openSession(attempt.id);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _startError = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// The runner says the attempt is over (submitted, time, integrity).
  Future<void> _finished(String attemptId) async {
    ref.read(analyticsProvider).event('quiz_submit');
    HapticFeedback.lightImpact();
    refreshAssessments(ref, widget.courseId);
    try {
      _attempts = await ref
          .read(assessmentRepositoryProvider)
          .attempts(widget.courseId, widget.quizId);
      await _showResults(attemptId);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _phase = _Phase.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    return switch (_phase) {
      _Phase.running => QuizRunner(
        key: ValueKey(_session!.attemptId),
        courseId: widget.courseId,
        quizId: widget.quizId,
        title: quiz?.title ?? '',
        session: _session!,
        onFinished: _finished,
      ),
      _ => ScrollTitleScaffold(
        title: _quiz?.title ?? '',
        body: SafeArea(
          top: false,
          child: switch (_phase) {
            _Phase.loading => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            _Phase.error => _ErrorView(
              message: _error == null
                  ? context.l10n.loadFailed
                  : errorText(ref, context, _error!),
              onRetry: _load,
            ),
            _Phase.results => QuizResultsView(
              courseId: widget.courseId,
              quiz: quiz!,
              results: _results!,
              attempts: _attempts,
              onRetake: () => _load(intro: true),
            ),
            _ => _Intro(
              quiz: quiz!,
              attempts: _attempts,
              starting: _starting,
              error: _startError,
              onStart: _start,
            ),
          },
        ),
      ),
    };
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AtlasSpace.gutter),
    children: [
      ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasBanner(kind: AtlasBannerKind.error, message: message),
            const SizedBox(height: AtlasSpace.s12),
            AtlasButton(
              label: context.l10n.commonRetry,
              style: AtlasButtonStyle.tonal,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    ],
  );
}

String dateTimeText(BuildContext context, DateTime d) =>
    context.digits(DateFormat.yMMMd(context.languageCode).add_jm().format(d));

/// Everything the learner needs to decide before Start: the time limit,
/// attempts used and left, the dates, the passing score, which attempt
/// counts — and, when the academy turned integrity on, exactly what is
/// recorded, acknowledged before Start enables.
class _Intro extends StatefulWidget {
  const _Intro({
    required this.quiz,
    required this.attempts,
    required this.starting,
    required this.error,
    required this.onStart,
  });

  final Quiz quiz;
  final List<QuizAttempt> attempts;
  final bool starting;
  final String? error;
  final VoidCallback onStart;

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  late bool _ack = !widget.quiz.settings.integrityOn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final q = widget.quiz;
    final s = q.settings;
    // A voided attempt is given back: it does not count as used.
    final used = widget.attempts
        .where((t) => !t.isOpen && t.status != 'invalidated')
        .length;
    final allowed = q.attemptsAllowed;
    final left = allowed == null ? null : (allowed - used).clamp(0, 1 << 30);
    final d = context.digits;
    final facts = <(String, String)>[
      (l.quizFactQuestions, d('${q.questionCount}')),
      (
        l.quizFactTime,
        s.timeLimitSeconds == null
            ? l.quizNoTimeLimit
            : l.minutes(d('${(s.timeLimitSeconds! / 60).ceil()}')),
      ),
      (
        l.quizFactAttempts,
        allowed == null
            ? l.quizAttemptsUnlimited(d('$used'))
            : l.quizAttemptsOf(d('$used'), d('$allowed')),
      ),
      if (q.passingScore != null)
        (l.quizFactPassing, l.quizPercent(d('${q.passingScore}'))),
      if (s.availableFrom != null)
        (l.quizFactOpens, dateTimeText(context, s.availableFrom!)),
      if (s.dueAt != null) (l.quizFactDue, dateTimeText(context, s.dueAt!)),
      if (s.availableUntil != null)
        (l.quizFactCloses, dateTimeText(context, s.availableUntil!)),
      (
        l.quizFactCounts,
        switch (s.gradingPolicy) {
          'latest' => l.quizPolicyLatest,
          'first' => l.quizPolicyFirst,
          'average' => l.quizPolicyAverage,
          _ => l.quizPolicyHighest,
        },
      ),
    ];
    final noneLeft = left == 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        0,
        AtlasSpace.gutter,
        48,
      ),
      children: [
        ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AtlasSpace.s8),
              AssessmentHeader(
                icon: LucideIcons.listChecks,
                kind: l.unitQuiz,
                title: q.title,
              ),
              const SizedBox(height: AtlasSpace.s8),
              Text(
                (q.description?.trim().isNotEmpty ?? false)
                    ? q.description!
                    : l.quizInstructionsDefault,
                style: a.type.body.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: AtlasSpace.s16),
              FactList(facts: facts),
              if (s.dueAt != null && !noneLeft)
                AddToCalendarButton(
                  title: q.title,
                  kind: l.unitQuiz,
                  dueAt: s.dueAt!,
                ),
              if (s.timeLimitSeconds != null) ...[
                const SizedBox(height: AtlasSpace.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.timer, size: 18, color: c.inkSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.quizTimerNote,
                        style: a.type.footnote.copyWith(color: c.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              if (s.integrityOn) ...[
                const SizedBox(height: AtlasSpace.s20),
                _Disclosure(
                  settings: s,
                  ack: _ack,
                  onAck: (v) => setState(() => _ack = v),
                ),
              ],
              if (widget.error != null) ...[
                const SizedBox(height: AtlasSpace.s16),
                AtlasBanner(
                  kind: AtlasBannerKind.error,
                  message: widget.error!,
                ),
              ],
              const SizedBox(height: AtlasSpace.s24),
              AtlasButton(
                label: l.quizStart,
                icon: LucideIcons.play,
                loading: widget.starting,
                onPressed: _ack && !noneLeft ? widget.onStart : null,
              ),
              if (left != null) ...[
                const SizedBox(height: AtlasSpace.s8),
                Text(
                  l.quizAttemptsLeft(left, d('$left')),
                  textAlign: TextAlign.center,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.settings,
    required this.ack,
    required this.onAck,
  });

  final QuizSettings settings;
  final bool ack;
  final ValueChanged<bool> onAck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final n = context.digits('${settings.maxViolations}');
    final p = a.type.subhead.copyWith(color: c.ink);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 20, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.quizIntegrityTitle,
                  style: a.type.headline.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l.quizIntegrityRecorded, style: p),
          const SizedBox(height: 8),
          Text(switch (settings.integrityMode) {
            'strict' => l.quizIntegrityStrict(n),
            'warn' => l.quizIntegrityWarn(n),
            _ => l.quizIntegrityMonitor,
          }, style: p),
          if (settings.requireFullscreen) ...[
            const SizedBox(height: 8),
            Text(l.quizIntegrityFullscreen, style: p),
          ],
          const SizedBox(height: 8),
          Text(
            l.quizIntegrityHonest,
            style: a.type.subhead.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: 8),
          CheckboxRow(
            value: ack,
            onChanged: onAck,
            label: TextSpan(text: l.quizIntegrityAck),
          ),
        ],
      ),
    );
  }
}
