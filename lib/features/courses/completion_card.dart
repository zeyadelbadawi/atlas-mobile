import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';

/// What the course still needs before it counts as completed, as the
/// server judges it: the required lessons, each required quiz and
/// assignment (a tap opens it), the minimum overall score, and what that
/// means for the certificate.
class CompletionChecklist extends StatelessWidget {
  const CompletionChecklist({
    super.key,
    required this.courseId,
    required this.completion,
  });

  final String courseId;
  final CourseCompletion completion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final k = completion;
    final required = k.lessonsRequired;
    String pct(double v) => context.digits('${v.round()}');

    return AtlasCard(
      key: const ValueKey('completion-checklist'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.completionTitle,
              style: a.type.title3.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.completionHint,
            style: a.type.subhead.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: 8),
          if (required > 0)
            _Row(
              state: k.lessonsCompleted >= required
                  ? RequirementState.done
                  : RequirementState.todo,
              title: l.completionLessons(
                context.digits('${k.lessonsCompleted.clamp(0, required)}'),
                context.digits('$required'),
              ),
            ),
          for (final q in k.quizzes)
            _Row(
              state: q.state,
              title: q.title,
              status: switch (q.state) {
                RequirementState.done => l.completionQuizPassed(
                  pct(q.score ?? 0),
                ),
                RequirementState.waiting => l.completionQuizPending,
                RequirementState.todo => l.completionQuizNotPassed,
              },
              onTap: () => context.push('/course/$courseId/quiz/${q.id}'),
            ),
          for (final x in k.assignments)
            _Row(
              state: x.state,
              title: x.title,
              status: switch (x.state) {
                RequirementState.done =>
                  x.score == null
                      ? l.completionAssignmentGradedNoScore
                      : l.completionAssignmentGraded(pct(x.score!)),
                RequirementState.waiting => l.completionAssignmentSubmitted,
                RequirementState.todo => l.completionAssignmentNotSubmitted,
              },
              onTap: () => context.push('/course/$courseId/assignment/${x.id}'),
            ),
          if (k.minOverallScore != null)
            _Row(
              state: k.minScoreMet
                  ? RequirementState.done
                  : RequirementState.todo,
              title: k.overallScore == null
                  ? l.completionMinScoreNone(pct(k.minOverallScore!))
                  : l.completionMinScore(
                      pct(k.minOverallScore!),
                      pct(k.overallScore!),
                    ),
            ),
          if (k.certificateEnabled) ...[
            Divider(height: 1, color: c.rule),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.award, size: 20, color: c.goldText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      k.certificateMinScore == null
                          ? l.completionCertificateNotYet
                          : l.completionCertificateNotYetMin(
                              pct(k.certificateMinScore!),
                            ),
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.state,
    required this.title,
    this.status,
    this.onTap,
  });

  final RequirementState state;
  final String title;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final (icon, color, said) = switch (state) {
      RequirementState.done => (
        LucideIcons.circleCheck,
        c.success,
        l.completionStateDone,
      ),
      RequirementState.waiting => (
        LucideIcons.clock,
        c.goldText,
        l.completionStateWaiting,
      ),
      RequirementState.todo => (
        LucideIcons.circle,
        c.inkTertiary,
        l.completionStateTodo,
      ),
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection: contentDirection(context, title),
                  style: a.type.headline.copyWith(
                    color: state == RequirementState.done
                        ? c.inkSecondary
                        : c.ink,
                  ),
                ),
                if (status != null)
                  Text(
                    status!,
                    style: a.type.footnote.copyWith(color: c.inkSecondary),
                  ),
              ],
            ),
          ),
          if (onTap != null) const ForwardChevron(),
        ],
      ),
    );
    return MergeSemantics(
      child: Semantics(
        value: said,
        button: onTap != null,
        child: onTap == null
            ? row
            : Pressable(onTap: onTap, scale: 0.99, child: row),
      ),
    );
  }
}
