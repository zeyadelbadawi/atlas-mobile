import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';
import '../learning/course_widgets.dart';

/// Home: the academy's cover, the bookmark on where the learner stopped,
/// what is due, the academy's latest announcements and the courses.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(overviewProvider);
    ref.invalidate(enrollmentsProvider);
    await ref.read(overviewProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final academy = session.academy!;
    final name = session.displayName.split(' ').first;
    final overview = ref.watch(overviewProvider);
    final courses = ref.watch(enrollmentsProvider);

    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () => _refresh(ref),
        edgeOffset: MediaQuery.paddingOf(context).top,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CoverBand.home(
              academyName: academy.name,
              greeting: name.isEmpty ? academy.name : l.homeGreeting(name),
              logo: NetworkImage(academy.logoUrl.toString()),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpace.gutter,
                ),
                child: ReadableWidth(
                  child: AsyncBody<LearnerOverview>(
                    value: overview,
                    onRetry: () => ref.invalidate(overviewProvider),
                    data: (o) =>
                        _Body(overview: o, courses: courses.value ?? const []),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.overview, required this.courses});
  final LearnerOverview overview;
  final List<EnrolledCourse> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final academy = ref.watch(sessionProvider).academy!;
    // Where to continue: the overview's pick, else the first unfinished course.
    final continueCourseId =
        overview.continueLearning.firstOrNull?.courseId ??
        courses
            .where((c) => c.learningState != 'completed' && c.isActive)
            .firstOrNull
            ?.courseId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (continueCourseId != null)
          ContinueForCourse(courseId: continueCourseId)
        else
          _EmptyPanel(
            title: courses.isEmpty ? l.homeEmptyTitle : l.homeAllDone,
            body: courses.isEmpty ? l.homeEmptyBody(academy.name) : null,
          ),
        if (overview.deadlines.isNotEmpty) ...[
          SectionHeader(title: l.homeDueSoon),
          for (final d in overview.deadlines.take(4))
            DueRow(
              day: context.digits('${d.dueAt.day}'),
              weekday: weekdayShort(context, d.dueAt),
              title: d.title,
              meta: d.overdue
                  ? '${l.overdue}${context.sep}${timeOfDay(context, d.dueAt)}'
                  : '${d.courseTitle}${context.sep}${timeOfDay(context, d.dueAt)}',
              icon: itemIcon(d.type),
              changed: d.overdue,
              onTap: () => context.push(switch (d.type) {
                'quiz' => '/course/${d.courseId}/quiz/${d.id}',
                'assignment' => '/course/${d.courseId}/assignment/${d.id}',
                _ => '/course/${d.courseId}',
              }),
            ),
        ],
        if (overview.recentResults.isNotEmpty) ...[
          SectionHeader(
            title: l.resultsRecent,
            action: l.resultsSeeAll,
            onAction: () => context.push('/account/results'),
          ),
          for (final r in overview.recentResults.take(2))
            RecentResultRow(item: r),
        ],
        if (overview.announcements.isNotEmpty) ...[
          SectionHeader(title: l.homeAnnouncements),
          for (final n in overview.announcements.take(2))
            AnnouncementRow(item: n),
        ],
        if (courses.isNotEmpty) ...[
          SectionHeader(
            title: l.homeMyCourses,
            action: courses.length > 3 ? l.homeSeeAll : null,
            onAction: () => context.go('/courses'),
          ),
          for (final (i, c) in courses.take(3).indexed)
            EnrolledCourseRow(course: c, number: i + 1),
        ],
        SizedBox(height: 96 + MediaQuery.paddingOf(context).bottom - 40),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, this.body});
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: a.colors.raised,
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
        border: Border.all(color: a.colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.bookOpen, color: a.colors.accent, size: 28),
          const SizedBox(height: 12),
          Text(title, style: a.type.title3.copyWith(color: a.colors.ink)),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(
              body!,
              style: a.type.subhead.copyWith(color: a.colors.inkSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
