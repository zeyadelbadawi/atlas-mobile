import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';
import '../quiz/assessment_widgets.dart';

/// "My results": the three numbers that answer "how am I doing?", then
/// every quiz and assignment by course. A null average is "no scores yet",
/// never 0.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final value = ref.watch(studentResultsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(studentResultsProvider.future),
        child: ListView(
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
                  Semantics(
                    header: true,
                    child: Text(
                      l.resultsTitle,
                      style: a.type.title1.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  AsyncBody<StudentResults>(
                    value: value,
                    onRetry: () => ref.invalidate(studentResultsProvider),
                    data: (r) => _Results(results: r),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.results});
  final StudentResults results;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final r = results;
    final d = context.digits;
    if (r.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(LucideIcons.chartColumn, size: 36, color: c.inkTertiary),
            const SizedBox(height: 12),
            Text(
              l.resultsEmptyTitle,
              style: a.type.title3.copyWith(color: c.ink),
            ),
            const SizedBox(height: 4),
            Text(
              l.resultsEmptyBody,
              textAlign: TextAlign.center,
              style: a.type.subhead.copyWith(color: c.inkSecondary),
            ),
          ],
        ),
      );
    }
    final graded = [
      for (final c in r.courses)
        for (final q in c.quizzes)
          if (q.score != null) q,
    ].length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          child: AtlasCard(
            child: _Summary(
              ring: MergeSemantics(
                child: Column(
                  children: [
                    ScoreRing(
                      value: (r.averageQuizScore ?? 0) / 100,
                      size: 104,
                      child: Text(
                        r.averageQuizScore == null
                            ? '—'
                            : percentText(context, r.averageQuizScore!),
                        style: a.type.title2.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.averageQuizScore == null
                          ? l.resultsNoScores
                          : l.resultsAverage,
                      textAlign: TextAlign.center,
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              metrics: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Of the quizzes already graded: one awaiting a teacher
                  // is not a failed one.
                  _Metric(
                    icon: LucideIcons.circleCheck,
                    value: graded == 0
                        ? '—'
                        : l.countOf(d('${r.quizzesPassed}'), d('$graded')),
                    label: l.resultsQuizzesPassed,
                  ),
                  Divider(height: 24, color: c.rule),
                  _Metric(
                    icon: LucideIcons.graduationCap,
                    value: l.countOf(
                      d('${r.coursesCompleted}'),
                      d('${r.coursesEnrolled}'),
                    ),
                    label: l.resultsCoursesCompleted,
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final course in r.courses)
          if (course.quizzes.isNotEmpty || course.assignments.isNotEmpty) ...[
            SectionHeader(title: course.courseTitle),
            for (final q in course.quizzes)
              ResultRow(
                icon: itemIcon('quiz'),
                title: q.title,
                meta: [
                  l.quizAttemptN(d('${q.attemptNumber}')),
                  if (q.submittedAt != null) shortDate(context, q.submittedAt!),
                ].join(context.sep),
                trailing: q.score == null
                    ? StatusPill(label: l.resultsAwaiting)
                    : ScoreText(
                        text: percentText(context, q.score!),
                        passed: q.passed,
                      ),
                onTap: () =>
                    context.push('/course/${course.courseId}/quiz/${q.quizId}'),
              ),
            for (final s in course.assignments)
              ResultRow(
                icon: itemIcon('assignment'),
                title: s.title,
                meta: [
                  if (s.submittedAt != null) shortDate(context, s.submittedAt!),
                  if (s.hasFeedback) l.resultsHasFeedback,
                ].join(context.sep),
                trailing: !s.graded
                    ? StatusPill(label: l.resultsAwaiting)
                    : s.score == null
                    ? StatusPill(
                        label: l.assignmentGradedNoScore,
                        tone: PillTone.success,
                      )
                    : ScoreText(text: numberText(context, s.score!)),
                onTap: () => context.push(
                  '/course/${course.courseId}/assignment/${s.assignmentId}',
                ),
              ),
          ],
      ],
    );
  }
}

/// The ring beside the two numbers; with large text, the ring above them.
class _Summary extends StatelessWidget {
  const _Summary({required this.ring, required this.metrics});
  final Widget ring, metrics;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.35) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ring,
          const SizedBox(height: AtlasSpace.s20),
          metrics,
        ],
      );
    }
    return Row(
      children: [
        ring,
        const SizedBox(width: AtlasSpace.s20),
        Expanded(child: metrics),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: c.accent)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: a.type.title3.copyWith(color: c.ink)),
                Text(
                  label,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreText extends StatelessWidget {
  const ScoreText({super.key, required this.text, this.passed});
  final String text;
  final bool? passed;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Text(
      text,
      style: a.type.title3.copyWith(color: passed == false ? c.danger : c.ink),
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title, meta;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c.inkSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textDirection: contentDirection(context, title),
                      style: a.type.headline.copyWith(color: c.ink),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: a.type.footnote.copyWith(color: c.inkSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
