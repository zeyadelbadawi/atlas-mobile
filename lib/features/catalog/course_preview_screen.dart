import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/catalog_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';
import 'catalog_screen.dart' show CatalogCourseRow;
import 'reviews.dart';

/// A course the learner may not have joined yet: what it covers, its
/// content outline, and "Join for free" (or "Open course" once joined).
/// Reached from the catalog and from academy links (`/courses/:idOrSlug`).
class CoursePreviewScreen extends ConsumerWidget {
  const CoursePreviewScreen({super.key, required this.idOrSlug});
  final String idOrSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final course = ref.watch(catalogCourseProvider(idOrSlug));
    final c = a.colors;
    final loaded = course.value;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _Cover(course: loaded),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AtlasSpace.gutter,
                    AtlasSpace.s20,
                    AtlasSpace.gutter,
                    48,
                  ),
                  child: ReadableWidth(
                    // Errors show at once, not after the background retries.
                    child:
                        (course.hasError && !course.hasValue
                                ? AsyncValue<CatalogCourse>.error(
                                    course.error!,
                                    course.stackTrace ?? StackTrace.empty,
                                  )
                                : course)
                            .when(
                              data: (c) => _Preview(course: c),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(48),
                                child: Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              ),
                              error: (e, _) =>
                                  e is AtlasApiException && e.status == 404
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 40,
                                      ),
                                      child: Text(
                                        l.previewNotFound,
                                        textAlign: TextAlign.center,
                                        style: a.type.body.copyWith(
                                          color: c.inkSecondary,
                                        ),
                                      ),
                                    )
                                  : LoadError(
                                      onRetry: () => ref.invalidate(
                                        catalogCourseProvider(idOrSlug),
                                      ),
                                    ),
                            ),
                  ),
                ),
              ],
            ),
            const CoverBackButton(),
          ],
        ),
      ),
      // Joining stays in reach however far the learner has read.
      bottomNavigationBar: loaded == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: c.raised,
                border: Border(top: BorderSide(color: c.rule)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AtlasSpace.gutter,
                    AtlasSpace.s12,
                    AtlasSpace.gutter,
                    AtlasSpace.s12,
                  ),
                  child: ReadableWidth(child: _JoinButton(course: loaded)),
                ),
              ),
            ),
    );
  }
}

/// The course's picture across the top (or, without one, the academy's
/// cover colour with the Atlas book mark), under a soft scrim so the back
/// button reads on any image.
class _Cover extends StatelessWidget {
  const _Cover({this.course});
  final CatalogCourse? course;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    final top = MediaQuery.paddingOf(context).top;
    final url = course?.thumbnailUrl;
    return SizedBox(
      height: top + 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: c.cover),
            )
          else
            ColoredBox(
              color: c.cover,
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 20,
                    bottom: 12,
                  ),
                  child: ExcludeSemantics(
                    child: AtlasMark(
                      size: 150,
                      color: c.onCover.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x59000000), Color(0x00000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({required this.course});
  final CatalogCourse course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final facts = [
      if (course.totalSections > 0)
        l.previewUnits(
          course.totalSections,
          context.digits('${course.totalSections}'),
        ),
      l.lessonsCount(
        course.totalLessons,
        context.digits('${course.totalLessons}'),
      ),
      if (course.totalQuizzes > 0)
        l.previewQuizzes(
          course.totalQuizzes,
          context.digits('${course.totalQuizzes}'),
        ),
      if (course.totalAssignments > 0)
        l.previewAssignments(
          course.totalAssignments,
          context.digits('${course.totalAssignments}'),
        ),
      if (course.durationSeconds != null && course.durationSeconds! > 0)
        _duration(context, course.durationSeconds!),
      ?_level(context, course.level),
    ];
    final curriculum = ref.watch(curriculumProvider(course.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            course.title,
            textDirection: contentDirection(context, course.title),
            style: a.type.title1.copyWith(color: c.ink),
          ),
        ),
        if (course.instructors.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            course.instructors.join(context.sep),
            textDirection: contentDirection(context, course.instructors.first),
            style: a.type.subhead.copyWith(color: c.inkSecondary),
          ),
        ],
        if (course.totalReviews > 0) ...[
          const SizedBox(height: AtlasSpace.s8),
          RatingBadge(
            average: course.averageRating,
            total: course.totalReviews,
          ),
        ],
        const SizedBox(height: AtlasSpace.s12),
        Text(
          facts.join(context.sep),
          style: a.type.caption.copyWith(color: c.inkSecondary),
        ),
        if (course.certificatesEnabled) ...[
          const SizedBox(height: AtlasSpace.s8),
          Row(
            children: [
              Icon(LucideIcons.award, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                l.previewCertificate,
                style: a.type.caption.copyWith(color: c.accent),
              ),
            ],
          ),
        ],
        if ((course.description ?? course.shortDescription) case final text?
            when text.isNotEmpty) ...[
          SectionHeader(title: l.previewAbout),
          Text(
            text,
            textDirection: contentDirection(context, text),
            style: a.type.body.copyWith(color: c.ink),
          ),
        ],
        if (course.outcomes.isNotEmpty) ...[
          SectionHeader(title: l.previewOutcomes),
          for (final o in course.outcomes) _Bullet(text: o, check: true),
        ],
        if (course.requirements.isNotEmpty) ...[
          SectionHeader(title: l.previewRequirements),
          for (final r in course.requirements) _Bullet(text: r),
        ],
        if (curriculum.value case final sections? when sections.isNotEmpty) ...[
          SectionHeader(title: l.previewContent),
          for (final (i, s) in sections.indexed) ...[
            Padding(
              padding: const EdgeInsets.only(top: AtlasSpace.s8, bottom: 4),
              child: Text(
                '${l.courseUnit(context.digits('${i + 1}'))}${context.sep}${s.title}',
                style: a.type.headline.copyWith(color: c.ink),
              ),
            ),
            for (final lesson in s.lessons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _lessonIcon(lesson.contentType),
                      size: 16,
                      color: c.inkSecondary,
                    ),
                    const SizedBox(width: AtlasSpace.s8),
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: a.type.subhead.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
        CourseReviewsSection(courseId: course.id, total: course.totalReviews),
        _MoreCourses(courseId: course.id),
      ],
    );
  }

  static IconData _lessonIcon(String contentType) => switch (contentType) {
    'video' => LucideIcons.circlePlay,
    'file' => LucideIcons.paperclip,
    _ => LucideIcons.bookOpen,
  };

  static String _duration(BuildContext context, int seconds) {
    final l = context.l10n;
    final minutes = (seconds / 60).round();
    if (minutes < 60) return l.minutes(context.digits('$minutes'));
    return l.previewHours(
      context.digits('${minutes ~/ 60}'),
      context.digits('${minutes % 60}'),
    );
  }

  static String? _level(BuildContext context, String? level) {
    final l = context.l10n;
    return switch (level) {
      'beginner' => l.levelBeginner,
      'intermediate' => l.levelIntermediate,
      'advanced' => l.levelAdvanced,
      'all_levels' => l.levelAll,
      _ => null,
    };
  }
}

/// Related free courses, when the academy has any.
class _MoreCourses extends ConsumerWidget {
  const _MoreCourses({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final more = ref.watch(recommendationsProvider(courseId)).value ?? const [];
    final list = more.where((c) => c.id != courseId).take(4).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('more-courses'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.previewMore),
        for (final (i, c) in list.indexed)
          CatalogCourseRow(course: c, number: i + 1),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.check = false});
  final String text;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              check ? LucideIcons.check : LucideIcons.dot,
              size: 16,
              color: check ? a.colors.accent : a.colors.inkSecondary,
            ),
          ),
          const SizedBox(width: AtlasSpace.s8),
          Expanded(
            child: Text(
              text,
              textDirection: contentDirection(context, text),
              style: a.type.body.copyWith(color: a.colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends ConsumerStatefulWidget {
  const _JoinButton({required this.course});
  final CatalogCourse course;

  @override
  ConsumerState<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<_JoinButton> {
  bool _busy = false;
  String? _error;

  Future<void> _join() async {
    final l = context.l10n;
    final course = widget.course;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(catalogRepositoryProvider).enroll(course.id);
      ref.read(analyticsProvider).event('course_join');
      HapticFeedback.lightImpact();
      ref.invalidate(enrollmentsProvider);
      ref.invalidate(overviewProvider);
      ref.invalidate(isEnrolledProvider(course.id));
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l.previewJoinedToast(course.title))),
      );
      context.pushReplacement('/course/${course.id}');
    } on Object catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            e is AtlasApiException &&
                e.messageKey == 'errors.entitlement.limitReached'
            ? l.enrollLimitReached
            : errorText(ref, context, e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final course = widget.course;
    if (!course.isFree) {
      return AtlasBanner(kind: AtlasBannerKind.info, message: l.previewNotFree);
    }
    final enrolled = ref.watch(isEnrolledProvider(course.id)).value ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
          const SizedBox(height: AtlasSpace.s12),
        ],
        if (enrolled)
          AtlasButton(
            label: l.previewOpen,
            icon: LucideIcons.play,
            onPressed: () => context.pushReplacement('/course/${course.id}'),
          )
        else
          AtlasButton(
            label: l.previewJoin,
            loading: _busy,
            onPressed: _busy ? null : _join,
          ),
      ],
    );
  }
}
