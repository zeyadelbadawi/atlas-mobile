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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Metric(
              value: r.averageQuizScore == null
                  ? '—'
                  : percentText(context, r.averageQuizScore!),
              label: r.averageQuizScore == null
                  ? l.resultsNoScores
                  : l.resultsAverage,
            ),
            _Metric(
              value: l.countOf(
                d('${r.quizzesPassed}'),
                d('${r.quizzesAttempted}'),
              ),
              label: l.resultsQuizzesPassed,
            ),
            _Metric(
              value: l.countOf(
                d('${r.coursesCompleted}'),
                d('${r.coursesEnrolled}'),
              ),
              label: l.resultsCoursesCompleted,
            ),
          ],
        ),
        for (final course in r.courses)
          if (course.quizzes.isNotEmpty || course.assignments.isNotEmpty) ...[
            SectionHeader(title: course.courseTitle),
            for (final q in course.quizzes)
              _ResultRow(
                icon: itemIcon('quiz'),
                title: q.title,
                meta: [
                  l.quizAttemptN(d('${q.attemptNumber}')),
                  if (q.submittedAt != null) shortDate(context, q.submittedAt!),
                ].join(context.sep),
                trailing: q.score == null
                    ? StatusPill(label: l.resultsAwaiting)
                    : _Score(
                        text: percentText(context, q.score!),
                        passed: q.passed,
                      ),
                onTap: () =>
                    context.push('/course/${course.courseId}/quiz/${q.quizId}'),
              ),
            for (final s in course.assignments)
              _ResultRow(
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
                    : _Score(text: numberText(context, s.score!)),
                onTap: () => context.push(
                  '/course/${course.courseId}/assignment/${s.assignmentId}',
                ),
              ),
          ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: a.type.title1.copyWith(color: a.colors.ink)),
            Text(
              label,
              style: a.type.footnote.copyWith(color: a.colors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.text, this.passed});
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({
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
                    Text(title, style: a.type.headline.copyWith(color: c.ink)),
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
