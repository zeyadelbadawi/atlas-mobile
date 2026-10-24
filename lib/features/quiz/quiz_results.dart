import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import '../learning/course_widgets.dart';
import 'assessment_widgets.dart';
import 'quiz_screen.dart' show dateTimeText;

/// The result of one attempt, shown only as far as the academy's disclosure
/// policy allows: the score, why it was submitted when it wasn't the
/// learner's tap, each answer with the correct one and the explanation, the
/// attempt history, and what to do next.
class QuizResultsView extends ConsumerWidget {
  const QuizResultsView({
    super.key,
    required this.courseId,
    required this.quiz,
    required this.results,
    required this.attempts,
    required this.onRetake,
  });

  final String courseId;
  final Quiz quiz;
  final QuizResults results;
  final List<QuizAttempt> attempts;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final r = results;
    final d = context.digits;
    final seq = ref.watch(sequenceProvider(courseId)).value;
    final next = seq?.after(quiz.id);
    final notices = <(String, String)>[
      if (r.status == 'invalidated')
        (l.quizInvalidatedTitle, l.quizInvalidated)
      else if (r.autoSubmitted && r.autoSubmittedReason == 'integrity')
        (l.quizAutoIntegrityTitle, l.quizAutoIntegrity)
      else if (r.autoSubmitted)
        (l.quizTimeRanOutTitle, l.quizTimeRanOut),
      if (r.pendingGrading) (l.quizAwaitingTitle, l.quizAwaiting),
    ];
    final withheld = switch (quiz.settings.showScore) {
      'after_due' => l.quizScoreWithheldDue,
      'after_attempts_exhausted' => l.quizScoreWithheldAttempts,
      'never' => l.quizScoreWithheldNever,
      _ => l.quizScoreWithheldSoon,
    };
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
              Text(
                '${quiz.title}${context.sep}${l.quizAttemptN(d('${r.attemptNumber}'))}',
                style: a.type.footnote.copyWith(color: c.inkSecondary),
              ),
              Semantics(
                header: true,
                child: Text(
                  r.showsScore ? l.quizResultTitle : l.quizSubmittedTitle,
                  style: a.type.title1.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(height: AtlasSpace.s16),
              if (r.showsScore && r.score != null)
                _ScoreBlock(results: r)
              else if (!r.pendingGrading)
                AtlasBanner(message: withheld),
              for (final (title, body) in notices) ...[
                const SizedBox(height: AtlasSpace.s12),
                AtlasBanner(message: '$title. $body'),
              ],
              if (r.isLate) ...[
                const SizedBox(height: AtlasSpace.s8),
                Text(
                  l.quizLate,
                  style: a.type.footnote.copyWith(color: c.warning),
                ),
              ],
              const SizedBox(height: AtlasSpace.s20),
              if (next != null && !next.isLocked)
                AtlasButton(
                  label: l.quizNextActivity,
                  icon: LucideIcons.arrowRight,
                  onPressed: () =>
                      openItem(context, ref, seq!, next, replace: true),
                )
              else
                AtlasButton(
                  label: l.quizBackToCourse,
                  onPressed: () => context.pop(),
                ),
              const SizedBox(height: AtlasSpace.s8),
              if (r.canRetry)
                AtlasButton(
                  label: l.quizRetake,
                  icon: LucideIcons.rotateCcw,
                  style: AtlasButtonStyle.tonal,
                  onPressed: onRetake,
                )
              else
                Text(
                  l.quizNoMoreAttempts,
                  textAlign: TextAlign.center,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
              if (r.questions.isNotEmpty) ...[
                SectionHeader(title: l.quizReviewTitle),
                if (!r.showsAnswers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l.quizAnswersWithheld,
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ),
                for (final (i, q) in r.questions.indexed)
                  _ReviewItem(
                    number: i + 1,
                    question: q,
                    labels: quiz.optionLabels,
                    showAnswers: r.showsAnswers,
                    onLesson: q.relatedLessonId == null
                        ? null
                        : () => context.push(
                            '/course/$courseId/lesson/${q.relatedLessonId}',
                          ),
                  ),
              ],
              if (attempts.length > 1) ...[
                SectionHeader(title: l.quizHistory),
                for (final t in attempts)
                  _AttemptRow(attempt: t, showScore: r.showsScore),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.results});
  final QuizResults results;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final r = results;
    return Panel(
      tonal: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                percentText(context, r.score!),
                style: a.type.numeral.copyWith(color: c.ink),
              ),
              const SizedBox(width: 12),
              if (r.passed != null)
                StatusPill(
                  label: r.passed! ? l.quizPassed : l.quizFailed,
                  tone: r.passed! ? PillTone.success : PillTone.danger,
                ),
            ],
          ),
          if (r.pointsEarned != null && r.pointsTotal != null)
            Text(
              l.quizPointsOf(
                numberText(context, r.pointsEarned!),
                numberText(context, r.pointsTotal!),
              ),
              style: a.type.subhead.copyWith(color: c.inkSecondary),
            ),
          if (r.passingScore != null)
            Text(
              l.quizPassingLine(context.digits('${r.passingScore}')),
              style: a.type.subhead.copyWith(color: c.inkSecondary),
            ),
          if (r.effectiveScore != null &&
              r.attemptsUsed > 1 &&
              r.effectiveScore!.round() != r.score!.round())
            Text(
              l.quizCounted(context.digits('${r.effectiveScore!.round()}')),
              style: a.type.subhead.copyWith(color: c.ink),
            ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({
    required this.number,
    required this.question,
    required this.labels,
    required this.showAnswers,
    this.onLesson,
  });

  final int number;
  final QuizResultQuestion question;
  final Map<String, String> labels;
  final bool showAnswers;
  final VoidCallback? onLesson;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final q = question;
    final (verdict, tone) = q.needsManualGrading && q.correct == null
        ? (l.quizVerdictPending, PillTone.neutral)
        : q.correct == true
        ? (l.quizVerdictCorrect, PillTone.success)
        : q.correct == false
        ? (l.quizVerdictIncorrect, PillTone.danger)
        : (l.quizVerdictRecorded, PillTone.neutral);
    final mine = q.yourAnswer;
    final isText = textQuestionTypes.contains(q.type);
    final correct = q.correctOptionIds ?? const <String>[];
    final missed = [
      for (final id in correct)
        if (!(mine?.selected.contains(id) ?? false)) id,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  context.digits('$number'),
                  style: a.type.title3.copyWith(color: c.inkSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  q.prompt,
                  style: a.type.headline.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: verdict, tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          if (!q.answered || mine == null)
            Text(
              l.quizNotAnswered,
              style: a.type.subhead.copyWith(color: c.inkTertiary),
            )
          else if (isText)
            _Line(label: l.quizYourAnswer, value: mine.text ?? '')
          else ...[
            _Label(l.quizYourAnswer),
            for (final id in mine.selected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionTile(
                  label: labels[id] ?? '—',
                  selected: true,
                  multiple: q.type == 'multiple_choice',
                  verdict: showAnswers ? correct.contains(id) : null,
                ),
              ),
          ],
          if (showAnswers && !isText && missed.isNotEmpty) ...[
            _Label(l.quizCorrectAnswer),
            for (final id in missed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionTile(
                  label: labels[id] ?? '—',
                  selected: false,
                  multiple: q.type == 'multiple_choice',
                  verdict: true,
                ),
              ),
          ],
          if (showAnswers && q.acceptedAnswers.isNotEmpty)
            _Line(
              label: l.quizAcceptedAnswers,
              value: q.acceptedAnswers.join(context.sep),
            ),
          if (q.explanation != null && q.explanation!.trim().isNotEmpty)
            _Line(label: l.quizExplanation, value: q.explanation!),
          if (onLesson != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onLesson,
                icon: const Icon(LucideIcons.bookOpen, size: 18),
                label: Text(l.quizReviewLesson),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: context.atlas.type.footnote.copyWith(
        color: context.atlas.colors.inkSecondary,
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: a.type.footnote.copyWith(color: a.colors.inkSecondary),
          ),
          Text(value, style: a.type.body.copyWith(color: a.colors.ink)),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt, required this.showScore});
  final QuizAttempt attempt;
  final bool showScore;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final t = attempt;
    final status = switch (t.status) {
      'passed' => l.quizPassed,
      'failed' => l.quizFailed,
      'invalidated' => l.quizInvalidatedTitle,
      'expired' => l.quizTimeRanOutTitle,
      _ => l.quizSubmittedTitle,
    };
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.rule)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.quizAttemptN(context.digits('${t.attemptNumber}')),
                    style: a.type.headline.copyWith(color: c.ink),
                  ),
                  Text(
                    [
                      status,
                      if (t.submittedAt != null)
                        dateTimeText(context, t.submittedAt!),
                    ].join(context.sep),
                    style: a.type.footnote.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            if (showScore && t.score != null)
              Text(
                percentText(context, t.score!),
                style: a.type.title3.copyWith(color: c.ink),
              ),
          ],
        ),
      ),
    );
  }
}
