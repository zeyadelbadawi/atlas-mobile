import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpace.gutter,
          0,
          AtlasSpace.gutter,
          48,
        ),
        children: [
          ReadableWidth(
            child: course.when(
              data: (c) => _Preview(course: c),
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => e is AtlasApiException && e.status == 404
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        l.previewNotFound,
                        textAlign: TextAlign.center,
                        style: a.type.body.copyWith(
                          color: a.colors.inkSecondary,
                        ),
                      ),
                    )
                  : LoadError(
                      onRetry: () =>
                          ref.invalidate(catalogCourseProvider(idOrSlug)),
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
        l.previewUnits(context.digits('${course.totalSections}')),
      l.lessonsCount(context.digits('${course.totalLessons}')),
      if (course.totalQuizzes > 0)
        l.previewQuizzes(context.digits('${course.totalQuizzes}')),
      if (course.totalAssignments > 0)
        l.previewAssignments(context.digits('${course.totalAssignments}')),
      if (course.durationSeconds != null && course.durationSeconds! > 0)
        _duration(context, course.durationSeconds!),
      ?_level(context, course.level),
    ];
    final curriculum = ref.watch(curriculumProvider(course.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (course.thumbnailUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AtlasRadius.lg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: c.tonal),
              ),
            ),
          ),
          const SizedBox(height: AtlasSpace.s16),
        ],
        Semantics(
          header: true,
          child: Text(
            course.title,
            style: a.type.title1.copyWith(color: c.ink),
          ),
        ),
        if (course.instructors.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            course.instructors.join(context.sep),
            style: a.type.subhead.copyWith(color: c.inkSecondary),
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
        const SizedBox(height: AtlasSpace.s20),
        _JoinButton(course: course),
        if ((course.description ?? course.shortDescription) case final text?
            when text.isNotEmpty) ...[
          SectionHeader(title: l.previewAbout),
          Text(text, style: a.type.body.copyWith(color: c.ink)),
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
            child: Text(text, style: a.type.body.copyWith(color: a.colors.ink)),
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
