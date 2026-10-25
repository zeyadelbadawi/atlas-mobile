import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import 'learning_ui.dart';

/// The Continue panel for one course: loads its sequence for the lesson
/// number, title and duration-weighted progress.
class ContinueForCourse extends ConsumerWidget {
  const ContinueForCourse({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final seq = ref.watch(sequenceProvider(courseId));
    return AsyncBody<CourseSequence>(
      value: seq,
      onRetry: () => ref.invalidate(sequenceProvider(courseId)),
      data: (s) {
        final item =
            s.continueItem ??
            s.items.where((i) => !i.isDone && !i.isLocked).firstOrNull;
        if (item == null) return const SizedBox.shrink();
        final left = minutesLeft(s);
        return ContinuePanel(
          unitLabel: unitLabel(context, item.type),
          lessonNumber: context.digits('${item.position + 1}'),
          lessonTitle: item.title,
          courseLine: '${s.courseTitle}${context.sep}${item.sectionTitle}',
          segments: segmentsFor(s),
          countLabel: l.countOf(
            context.digits('${s.completedCount}'),
            context.digits('${s.totalCount}'),
          ),
          timeLeft: left == null ? '' : l.minutesLeft(context.digits('$left')),
          resumeLabel: s.completedCount == 0 ? l.homeStart : l.homeResume,
          progressSemantics:
              '${l.countOf('${s.completedCount}', '${s.totalCount}')}, ${(s.completedCount * 100 / (s.totalCount == 0 ? 1 : s.totalCount)).round()}%',
          onResume: () => openItem(context, ref, s, item),
        );
      },
    );
  }
}

/// Opens a course item in the app: lessons in the player, quizzes and
/// assignments on their screens. Live sessions open on the academy's
/// website (Zoom in the app comes when the backend enables it).
/// [replace] swaps the current screen (lesson → next activity).
void openItem(
  BuildContext context,
  WidgetRef ref,
  CourseSequence s,
  SequenceItem item, {
  bool replace = false,
}) {
  final path = switch (item.type) {
    'lesson' => '/course/${s.courseId}/lesson/${item.id}',
    'quiz' => '/course/${s.courseId}/quiz/${item.id}',
    'assignment' => '/course/${s.courseId}/assignment/${item.id}',
    _ => null,
  };
  if (path != null) {
    replace ? context.pushReplacement(path) : context.push(path);
    return;
  }
  final host = ref.read(sessionProvider).academy!.host;
  launchUrl(
    Uri.https(host, '/my/courses/${s.courseId}/activities/${item.id}'),
    mode: LaunchMode.inAppBrowserView,
  );
}

class EnrolledCourseRow extends StatelessWidget {
  const EnrolledCourseRow({
    super.key,
    required this.course,
    required this.number,
  });
  final EnrolledCourse course;

  /// The course's place in the list, set on its generated cover (٠١, ٠٢…)
  /// like a handout's volume number.
  final int number;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = switch (course.learningState) {
      'completed' => l.coursesCompleted,
      'not_started' => l.coursesNotStarted,
      _ => l.percentDone(context.digits('${course.percentage.round()}')),
    };
    return CourseRow(
      title: course.title,
      subtitle: [
        if (course.instructors.isNotEmpty) course.instructors.join(context.sep),
        l.lessonsCount(course.total, context.digits('${course.total}')),
      ].join(context.sep),
      cover: CourseCover(
        image: course.thumbnailUrl == null
            ? null
            : NetworkImage(course.thumbnailUrl!),
        kicker: l.coursesCover,
        mark: context.digits(number.toString().padLeft(2, '0')),
      ),
      segments: segmentsFromCounts(course.completed, course.total),
      status: course.isActive ? status : l.courseAccessEnded,
      onTap: () => context.push('/course/${course.courseId}'),
    );
  }
}

class AnnouncementRow extends StatelessWidget {
  const AnnouncementRow({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: a.colors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: a.type.headline.copyWith(color: a.colors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            item.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: a.type.subhead.copyWith(color: a.colors.inkSecondary),
          ),
          if (item.publishedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              shortDate(context, item.publishedAt!),
              style: a.type.caption.copyWith(color: a.colors.inkTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A recent graded result on the home screen (opens "My results": the
/// overview names the attempt, not the quiz).
class RecentResultRow extends StatelessWidget {
  const RecentResultRow({super.key, required this.item});
  final RecentResult item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final score = item.score;
    return MergeSemantics(
      child: Pressable(
        onTap: () => context.push('/account/results'),
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              Icon(itemIcon(item.type), size: 20, color: c.inkSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: a.type.headline.copyWith(color: c.ink),
                    ),
                    Text(
                      item.courseTitle,
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                score == null
                    ? l.resultsAwaiting
                    : item.type == 'quiz'
                    ? l.quizPercent(context.digits('${score.round()}'))
                    : context.digits('${score.round()}'),
                style: (score == null ? a.type.footnote : a.type.title3)
                    .copyWith(
                      color: item.status == 'failed' ? c.danger : c.ink,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
