import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import '../player/watermark_overlay.dart';
import 'assessment_widgets.dart';
import 'quiz_engine.dart';

/// The attempt in progress.
///
/// Owns the answers and hands the rest to the engine: the clock (server
/// time), the autosave queue and the integrity record. When time runs out
/// nothing is decided here: the last edit is flushed and submitted, and the
/// server's results say what happened.
class QuizRunner extends ConsumerStatefulWidget {
  const QuizRunner({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.title,
    required this.session,
    required this.onFinished,
  });

  final String courseId;
  final String quizId;
  final String title;
  final QuizSession session;
  final Future<void> Function(String attemptId) onFinished;

  @override
  ConsumerState<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends ConsumerState<QuizRunner>
    with WidgetsBindingObserver {
  late final QuizSession s = widget.session;
  late AnswerMap _answers = toAnswerMap(s.answers);
  final _flagged = <String>{};
  final _text = <String, TextEditingController>{};
  int _index = 0;
  late final AttemptClock _clock = AttemptClock(
    serverNow: s.serverNow,
    deadlineAt: s.deadlineAt,
  );
  late final QuizAutosave _autosave;
  late final QuizIntegrity _integrity;
  Timer? _tick;
  int? _remaining;
  bool _submitting = false, _finished = false, _hidden = false;
  String? _submitError;
  (int, int)? _warning;
  bool _bannerShown = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(assessmentRepositoryProvider);
    _autosave = QuizAutosave(
      save: (rev, answers) => repo.saveAnswers(
        widget.courseId,
        widget.quizId,
        s.attemptId,
        revision: rev,
        answers: answers,
      ),
      initialRevision: s.revision,
      confirmed: s.answers,
      onSaved: (r) =>
          _clock.sync(serverNow: r.serverNow, deadlineAt: r.deadlineAt),
      onTerminal: () => _finish(),
      onRebased: (merged) {
        if (!mounted) return;
        setState(() => _answers = toAnswerMap(merged));
        _syncControllers();
      },
    )..state.addListener(_rebuild);
    _integrity = QuizIntegrity(
      record: (events) => repo.recordEvents(
        widget.courseId,
        widget.quizId,
        s.attemptId,
        events,
      ),
      mode: s.settings.integrityMode,
      onWarn: _onWarn,
      onAutoSubmitted: () => _finish(),
    )..start();
    _remaining = _clock.remaining();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    WidgetsBinding.instance.addObserver(this);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    unawaited(_autosave.flush().whenComplete(_autosave.dispose));
    _integrity.dispose();
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (_hidden) return;
        _hidden = true;
        _integrity.push('visibility_hidden');
        unawaited(_autosave.flush());
      case AppLifecycleState.resumed:
        if (!_hidden) return;
        _hidden = false;
        _integrity.push('visibility_visible');
        unawaited(_resync());
      default:
        break;
    }
  }

  /// After the app was away the phone's stopwatch may have stopped: ask the
  /// server for the time again (and whether the attempt is still open).
  Future<void> _resync() async {
    try {
      final fresh = await ref
          .read(assessmentRepositoryProvider)
          .session(widget.courseId, widget.quizId, s.attemptId);
      if (fresh.status != 'in_progress') return await _finish();
      _clock.sync(serverNow: fresh.serverNow, deadlineAt: fresh.deadlineAt);
      _onTick();
    } on Object catch (e) {
      if (isTerminalAttemptError(e)) await _finish();
    }
  }

  void _onTick() {
    final before = _remaining;
    final now = _clock.remaining();
    if (now == before) return;
    setState(() => _remaining = now);
    final crossed = crossedAnnouncement(before, now);
    if (crossed != null && mounted) {
      final l = context.l10n;
      final msg = crossed >= 60
          ? l.quizAnnounceMinutes(
              crossed ~/ 60,
              context.digits('${crossed ~/ 60}'),
            )
          : l.quizAnnounceSeconds(context.digits('$crossed'));
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          msg,
          Directionality.of(context),
        ),
      );
    }
    if (now == 0 && !_finished && !_submitting) unawaited(_finalize());
  }

  void _onWarn(int violations, int max) {
    if (!mounted || !s.settings.integrityWarns) return;
    setState(() => _warning = (violations, max));
    if (!_bannerShown) {
      setState(() => _bannerShown = true);
    } else {
      unawaited(_warnDialog(violations, max));
    }
  }

  Future<void> _warnDialog(int violations, int max) async {
    final l = context.l10n;
    final d = context.digits;
    await showAdaptiveDialog<void>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: Text(l.quizEventDialogTitle),
        content: Text(
          s.settings.integrityMode == 'strict'
              ? l.quizEventStrict(d('$violations'), d('$max'))
              : '${l.quizEventWarn(violations, d('$violations'))}\n${l.quizEventDialogWarn}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l.quizContinue),
          ),
        ],
      ),
    );
    _integrity.acknowledgeWarning();
  }

  /* ---------- answers ---------- */

  TextEditingController _controller(String questionId) => _text.putIfAbsent(
    questionId,
    () => TextEditingController(text: _answers[questionId]?.text ?? ''),
  );

  void _syncControllers() {
    for (final e in _text.entries) {
      final t = _answers[e.key]?.text ?? '';
      if (e.value.text != t) e.value.text = t;
    }
  }

  void _answer(QuizAnswer answer) {
    final prev = _answers[answer.questionId];
    if (prev != null && prev.sameAs(answer)) return;
    setState(() => _answers = {..._answers, answer.questionId: answer});
    _autosave.schedule(toAnswerList(s.questions, _answers));
  }

  void _toggle(QuizSessionQuestion q, String optionId) {
    final current = _answers[q.id]?.selected ?? const [];
    final next = q.isMultiple
        ? (current.contains(optionId)
              ? current.where((id) => id != optionId).toList()
              : [...current, optionId])
        : [optionId];
    _answer(QuizAnswer(questionId: q.id, selected: next));
  }

  /* ---------- submit ---------- */

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _tick?.cancel();
    await widget.onFinished(s.attemptId);
  }

  Future<void> _finalize() async {
    await _autosave.flush();
    try {
      await _send();
    } on Object {
      // Past the grace window the server already finalised it.
    }
    await _finish();
  }

  Future<void> _send() => ref
      .read(assessmentRepositoryProvider)
      .submit(
        widget.courseId,
        widget.quizId,
        s.attemptId,
        answers: toAnswerList(s.questions, _answers),
        revision: _autosave.nextRevision,
      );

  Future<void> _submit() async {
    final l = context.l10n;
    final missing = unansweredNumbers(s.questions, _answers);
    final d = context.digits;
    final ok = await confirmDialog(
      context,
      title: l.quizSubmitTitle,
      body: missing.isEmpty
          ? l.quizSubmitBody
          : l.quizSubmitUnanswered(
              missing.length,
              missing.map((n) => d('$n')).join(context.sep),
              d('${missing.length}'),
            ),
      confirm: l.quizSubmitConfirm,
      cancel: l.quizKeepAnswering,
    );
    if (!ok || !mounted) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _autosave.flush();
      await _send();
      await _finish();
    } on Object catch (e) {
      if (isTerminalAttemptError(e)) return _finish();
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = errorText(ref, context, e);
        });
      }
    }
  }

  Future<void> _leave() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.quizLeaveTitle,
      body: s.deadlineAt != null ? l.quizLeaveBody : l.quizLeaveTimedOff,
      confirm: l.quizLeave,
      cancel: l.quizStay,
    );
    if (!ok || !mounted) return;
    await _autosave.flush();
    if (mounted) Navigator.of(context).pop();
  }

  void _goTo(int i) =>
      setState(() => _index = i.clamp(0, s.questions.length - 1));

  /* ---------- build ---------- */

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final questions = s.questions;
    final paged =
        s.settings.layout == 'one_per_page' ||
        MediaQuery.sizeOf(context).width < 640;
    final user = ref.watch(sessionProvider).user;
    final last = _index >= questions.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: l.quizLeave,
            onPressed: _leave,
          ),
          title: Text(widget.title, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
              onPressed: _submitting ? null : _submit,
              child: Text(l.quizSubmitConfirm),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _Header(
                  remaining: _remaining,
                  hideTimer: s.settings.hideTimer,
                  answered: answeredCount(questions, _answers),
                  total: questions.length,
                  save: _autosave.state.value,
                ),
                if (_warning != null && _bannerShown)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AtlasSpace.gutter,
                      8,
                      AtlasSpace.gutter,
                      0,
                    ),
                    child: AtlasBanner(
                      message: s.settings.integrityMode == 'strict'
                          ? l.quizEventStrict(
                              context.digits('${_warning!.$1}'),
                              context.digits('${_warning!.$2}'),
                            )
                          : l.quizEventWarn(
                              _warning!.$1,
                              context.digits('${_warning!.$1}'),
                            ),
                    ),
                  ),
                _Navigator(
                  questions: questions,
                  answers: _answers,
                  flagged: _flagged,
                  current: paged ? _index : -1,
                  onSelect: _goTo,
                ),
                Expanded(
                  child: ListView(
                    key: PageStorageKey('q$_index'),
                    padding: const EdgeInsets.fromLTRB(
                      AtlasSpace.gutter,
                      AtlasSpace.s16,
                      AtlasSpace.gutter,
                      AtlasSpace.s32,
                    ),
                    children: [
                      ReadableWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, q) in questions.indexed)
                              if (!paged || i == _index)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AtlasSpace.s24,
                                  ),
                                  child: _QuestionCard(
                                    question: q,
                                    index: i,
                                    total: questions.length,
                                    answer: _answers[q.id],
                                    flagged: _flagged.contains(q.id),
                                    enabled: !_submitting,
                                    controller: q.isText
                                        ? _controller(q.id)
                                        : null,
                                    onToggle: (id) => _toggle(q, id),
                                    onText: (t) => _answer(
                                      QuizAnswer(questionId: q.id, text: t),
                                    ),
                                    onFlag: () => setState(
                                      () => _flagged.contains(q.id)
                                          ? _flagged.remove(q.id)
                                          : _flagged.add(q.id),
                                    ),
                                  ),
                                ),
                            if (_submitError != null) ...[
                              AtlasBanner(
                                kind: AtlasBannerKind.error,
                                message: _submitError!,
                              ),
                              const SizedBox(height: AtlasSpace.s12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomBar(
                  paged: paged,
                  first: _index == 0,
                  last: last,
                  submitting: _submitting,
                  onPrevious: () => _goTo(_index - 1),
                  onNext: () => _goTo(_index + 1),
                  onSubmit: _submit,
                ),
              ],
            ),
            if (s.settings.integrityOn && user != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: WatermarkOverlay(
                    code: user['name'] as String? ?? '',
                    secondary: user['email'] as String?,
                  ),
                ),
              ),
            if (_submitting)
              const Positioned.fill(child: ModalBarrier(dismissible: false)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.remaining,
    required this.hideTimer,
    required this.answered,
    required this.total,
    required this.save,
  });

  final int? remaining;
  final bool hideTimer;
  final int answered, total;
  final AutosaveState save;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final urgent = isUrgent(remaining);
    final saveText = switch (save) {
      AutosaveState.saving => l.quizSaving,
      AutosaveState.offline => l.quizOffline,
      AutosaveState.dirty => l.quizUnsaved,
      AutosaveState.saved => l.quizSaved,
      AutosaveState.idle => '',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        4,
        AtlasSpace.gutter,
        10,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rule)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (remaining != null && !hideTimer)
            Semantics(
              label: l.quizTimeLeft,
              value: formatCountdown(remaining!),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgent ? l.quizHurry : l.quizTimeLeft,
                    style: a.type.caption.copyWith(
                      color: urgent ? c.danger : c.inkSecondary,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      context.digits(formatCountdown(remaining!)),
                      style: a.type.title2.copyWith(
                        color: urgent ? c.danger : c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (remaining != null)
            Text(
              l.quizTimerHidden,
              style: a.type.footnote.copyWith(color: c.inkSecondary),
            ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l.quizAnswered(
                  context.digits('$answered'),
                  context.digits('$total'),
                ),
                style: a.type.footnote.copyWith(color: c.ink),
              ),
              Semantics(
                liveRegion: save == AutosaveState.offline,
                child: Text(
                  saveText,
                  style: a.type.caption.copyWith(
                    color: save == AutosaveState.offline
                        ? c.warning
                        : c.inkTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Numbered stops for every question: filled when answered, ringed when
/// current, with the bookmark when marked for review.
class _Navigator extends StatelessWidget {
  const _Navigator({
    required this.questions,
    required this.answers,
    required this.flagged,
    required this.current,
    required this.onSelect,
  });

  final List<QuizSessionQuestion> questions;
  final AnswerMap answers;
  final Set<String> flagged;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpace.gutter,
          vertical: 10,
        ),
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final q = questions[i];
          final done = answers[q.id]?.isAnswered ?? false;
          final flag = flagged.contains(q.id);
          final isCurrent = i == current;
          final state = flag
              ? l.quizStateFlagged
              : done
              ? l.quizStateAnswered
              : l.quizStateUnanswered;
          return Semantics(
            button: true,
            selected: isCurrent,
            label: l.quizNavItem(context.digits('${i + 1}'), state),
            excludeSemantics: true,
            child: Pressable(
              onTap: () => onSelect(i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AtlasMotion.quick,
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? c.tonal : c.sunken,
                      borderRadius: BorderRadius.circular(AtlasRadius.md),
                      border: Border.all(
                        color: isCurrent ? c.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      context.digits('${i + 1}'),
                      style: a.type.headline.copyWith(
                        color: done ? c.accent : c.inkSecondary,
                      ),
                    ),
                  ),
                  if (flag)
                    const PositionedDirectional(
                      end: 4,
                      top: -2,
                      child: Bookmark(width: 9, height: 14),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
    required this.answer,
    required this.flagged,
    required this.enabled,
    required this.controller,
    required this.onToggle,
    required this.onText,
    required this.onFlag,
  });

  final QuizSessionQuestion question;
  final int index, total;
  final QuizAnswer? answer;
  final bool flagged, enabled;
  final TextEditingController? controller;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onText;
  final VoidCallback onFlag;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final q = question;
    final d = context.digits;
    final points = q.points.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l.quizQuestionOf(d('${index + 1}'), d('$total'))}${context.sep}${l.quizPoints(points, d('$points'))}',
                style: a.type.footnote.copyWith(color: c.inkSecondary),
              ),
            ),
            Semantics(
              toggled: flagged,
              child: TextButton.icon(
                onPressed: onFlag,
                icon: Icon(
                  flagged ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                  size: 18,
                ),
                label: Text(flagged ? l.quizUnflag : l.quizFlag),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(q.prompt, style: a.type.title3.copyWith(color: c.ink)),
        ),
        const SizedBox(height: AtlasSpace.s8),
        if (q.isText)
          AnswerField(
            controller: controller!,
            label: l.quizYourAnswer,
            hint: l.quizTypeAnswer,
            helper: q.type == 'essay' ? l.quizEssayHint : l.quizShortHint,
            minLines: q.type == 'essay' ? 5 : 1,
            maxLines: q.type == 'essay' ? 12 : 3,
            enabled: enabled,
            onChanged: onText,
          )
        else ...[
          Text(
            q.isMultiple ? l.quizChooseAll : l.quizChooseOne,
            style: a.type.footnote.copyWith(color: c.inkTertiary),
          ),
          const SizedBox(height: AtlasSpace.s8),
          for (final o in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionTile(
                label: o.label,
                multiple: q.isMultiple,
                selected: answer?.selected.contains(o.id) ?? false,
                onTap: enabled ? () => onToggle(o.id) : null,
              ),
            ),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.paged,
    required this.first,
    required this.last,
    required this.submitting,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool paged, first, last, submitting;
  final VoidCallback onPrevious, onNext, onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.atlas.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      padding: EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        10,
        AtlasSpace.gutter,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ReadableWidth(
        child: Row(
          children: [
            if (paged) ...[
              Expanded(
                child: AtlasButton(
                  label: l.quizPrevious,
                  style: AtlasButtonStyle.tonal,
                  onPressed: first ? null : onPrevious,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: paged && !last
                  ? AtlasButton(label: l.quizNext, onPressed: onNext)
                  : AtlasButton(
                      label: l.quizSubmit,
                      icon: LucideIcons.send,
                      loading: submitting,
                      onPressed: submitting ? null : onSubmit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
