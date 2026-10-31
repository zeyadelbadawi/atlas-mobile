import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../learning/course_widgets.dart';
import '../learning/learning_ui.dart';
import 'completion_card.dart';

/// One course: progress, where to continue, and the syllabus by unit with
/// the bookmark on the current item.
class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseId = widget.courseId;
    final seq = ref.watch(sequenceProvider(courseId));
    // The list this course was opened from already knows its cover, title
    // and place, so the cover is whole from the first frame of the flight.
    final enrolled = ref.watch(enrollmentsProvider).value ?? const [];
    final index = enrolled.indexWhere((e) => e.courseId == courseId);
    final listed = index < 0 ? null : enrolled[index];
    final title = seq.value?.courseTitle ?? listed?.title ?? '';
    final c = context.atlas.colors;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: c.coverIsLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            RefreshIndicator.adaptive(
              edgeOffset: MediaQuery.paddingOf(context).top,
              onRefresh: () async {
                ref.invalidate(sequenceProvider(courseId));
                ref.invalidate(completionProvider(courseId));
                await ref.read(sequenceProvider(courseId).future);
              },
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  ScrollParallax(
                    controller: _scroll,
                    child: _CourseHero(
                      courseId: courseId,
                      title: title,
                      sequence: seq.value,
                      thumbnail: listed?.thumbnailUrl,
                      number: index < 0 ? null : index + 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AtlasSpace.gutter,
                      AtlasSpace.s20,
                      AtlasSpace.gutter,
                      48,
                    ),
                    child: ReadableWidth(
                      child: AsyncBody<CourseSequence>(
                        value: seq,
                        onRetry: () =>
                            ref.invalidate(sequenceProvider(courseId)),
                        data: (s) => _Course(s: s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CompactTitleBar(controller: _scroll, showAfter: 170, title: title),
            const CoverBackButton(),
          ],
        ),
      ),
    );
  }
}

/// The course's cover: the academy's colour with the course's own cover,
/// its title, where the learner is and the progress across its lessons.
class _CourseHero extends StatelessWidget {
  const _CourseHero({
    required this.courseId,
    required this.title,
    this.sequence,
    this.thumbnail,
    this.number,
  });

  final String courseId;
  final String title;
  final CourseSequence? sequence;
  final String? thumbnail;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final s = sequence;
    final left = s == null ? null : minutesLeft(s);
    return Container(
      color: c.cover,
      padding: EdgeInsetsDirectional.fromSTEB(
        AtlasSpace.gutter,
        MediaQuery.paddingOf(context).top + 60,
        AtlasSpace.gutter,
        AtlasSpace.s24,
      ),
      child: ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Hero(
                  tag: courseCoverTag(courseId),
                  child: CourseCover(
                    width: 84,
                    inverted: true,
                    image: thumbnail == null ? null : NetworkImage(thumbnail!),
                    kicker: l.coursesCover,
                    mark: number == null
                        ? null
                        : context.digits(number.toString().padLeft(2, '0')),
                  ),
                ),
                const SizedBox(width: AtlasSpace.s16),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textDirection: contentDirection(context, title),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: a.type.title1.copyWith(color: c.onCover),
                    ),
                  ),
                ),
              ],
            ),
            if (s != null) ...[
              const SizedBox(height: AtlasSpace.s20),
              SegmentedProgress(
                segments: segmentsFor(s),
                fill: c.onCover,
                track: c.onCover.withValues(alpha: 0.22),
              ),
              const SizedBox(height: AtlasSpace.s8),
              Row(
                children: [
                  Text(
                    l.countOf(
                      context.digits('${s.completedCount}'),
                      context.digits('${s.totalCount}'),
                    ),
                    style: a.type.caption.copyWith(
                      color: c.onCover.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  if (left != null)
                    Text(
                      l.minutesLeft(context.digits('$left')),
                      style: a.type.caption.copyWith(
                        color: c.onCover.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Course extends ConsumerWidget {
  const _Course({required this.s});
  final CourseSequence s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final next =
        s.continueItem ??
        s.items.where((i) => !i.isDone && !i.isLocked).firstOrNull;
    // Group by unit, keeping order.
    final units = <int, List<SequenceItem>>{};
    for (final i in s.items) {
      units.putIfAbsent(i.unitNumber, () => []).add(i);
    }
    // The server decides when a course is complete: every lesson done is
    // not enough while a required quiz is not passed.
    final completion = ref.watch(completionProvider(s.courseId)).value;
    final done = completion?.completed ?? s.finished;
    final checklist =
        completion != null &&
        !completion.completed &&
        (s.finished || completion.hasRequirementsBeyondLessons);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (done) _CompletedCard(courseId: s.courseId),
        if (next != null && !s.finished) ...[
          if (done) const SizedBox(height: AtlasSpace.s16),
          AtlasButton(
            label: s.completedCount == 0 ? l.homeStart : l.courseContinue,
            icon: LucideIcons.play,
            onPressed: () => openItem(context, ref, s, next),
          ),
        ],
        if (checklist) ...[
          if (next != null && !s.finished)
            const SizedBox(height: AtlasSpace.s16),
          CompletionChecklist(courseId: s.courseId, completion: completion),
        ],
        for (final entry in units.entries) ...[
          SectionHeader(
            title:
                '${l.courseUnit(context.digits('${entry.key}'))}${context.sep}${entry.value.first.sectionTitle}',
          ),
          for (final item in entry.value)
            SyllabusRow(
              item: item,
              current: item.id == next?.id && !s.finished,
              onTap: item.isLocked
                  ? () => explainLocked(context, item)
                  : () => openItem(context, ref, s, item),
            ),
        ],
      ],
    );
  }
}

class _CompletedCard extends ConsumerStatefulWidget {
  const _CompletedCard({required this.courseId});
  final String courseId;

  @override
  ConsumerState<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends ConsumerState<_CompletedCard> {
  Timer? _poll;
  int _polls = 0;

  /// While the certificate is being prepared, look again now and then
  /// (for about two minutes) so it appears without a pull to refresh.
  void _watch(String status) {
    if (status != 'eligible' || _poll != null || _polls >= 12) return;
    _poll = Timer(const Duration(seconds: 10), () {
      _poll = null;
      _polls++;
      if (mounted) ref.invalidate(completionProvider(widget.courseId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseId = widget.courseId;
    final l = context.l10n;
    final a = context.atlas;
    final completion = ref.watch(completionProvider(courseId)).value;
    final enabled = completion?.certificateEnabled ?? false;
    final status = completion?.certificateStatus;
    final issued = status == 'issued';
    if (enabled && status != null) _watch(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: a.colors.tonal,
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleCheckBig,
                color: a.colors.accent,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.courseCompletedTitle,
                      style: a.type.title3.copyWith(color: a.colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !enabled
                          ? l.courseCompletedBody
                          : issued
                          ? l.courseCertificateIssued
                          : status == 'revoked'
                          ? l.courseCertificateRevoked
                          : l.courseCertificatePending,
                      style: a.type.subhead.copyWith(
                        color: a.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (enabled && issued) ...[
            const SizedBox(height: 14),
            AtlasButton(
              label: l.courseOpenCertificates,
              icon: LucideIcons.award,
              onPressed: () => context.push('/account/certificates'),
            ),
          ],
        ],
      ),
    );
  }
}

/// A syllabus line: the item's number, title, kind and length or lock
/// reason, and its state. The current item carries the bookmark.
/// The course outline beside a lesson on a wide screen (iPad): every unit
/// and item, the open one marked; a tap replaces the open item, so Back
/// still returns to the course.
class CourseOutline extends ConsumerWidget {
  const CourseOutline({super.key, required this.s, required this.openId});
  final CourseSequence s;
  final String openId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final units = <int, List<SequenceItem>>{};
    for (final i in s.items) {
      units.putIfAbsent(i.unitNumber, () => []).add(i);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        AtlasSpace.s8,
        AtlasSpace.gutter,
        48,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            s.courseTitle,
            textDirection: contentDirection(context, s.courseTitle),
            style: a.type.title3.copyWith(color: a.colors.ink),
          ),
        ),
        const SizedBox(height: AtlasSpace.s12),
        SegmentedProgress(segments: segmentsFor(s)),
        const SizedBox(height: AtlasSpace.s8),
        Text(
          l.countOf(
            context.digits('${s.completedCount}'),
            context.digits('${s.totalCount}'),
          ),
          style: a.type.caption.copyWith(color: a.colors.inkSecondary),
        ),
        for (final entry in units.entries) ...[
          SectionHeader(
            title:
                '${l.courseUnit(context.digits('${entry.key}'))}${context.sep}${entry.value.first.sectionTitle}',
          ),
          for (final item in entry.value)
            SyllabusRow(
              item: item,
              current: item.id == openId,
              onTap: item.id == openId
                  ? null
                  : item.isLocked
                  ? () => explainLocked(context, item)
                  : () => openItem(context, ref, s, item, replace: true),
            ),
        ],
      ],
    );
  }
}

class SyllabusRow extends StatelessWidget {
  const SyllabusRow({
    super.key,
    required this.item,
    required this.current,
    this.onTap,
  });
  final SequenceItem item;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final lock = lockText(context, item);
    final meta = [
      unitLabel(context, item.type),
      if (lock != null)
        lock
      else if (item.durationSeconds != null && item.durationSeconds! > 0)
        l.minutes(context.digits('${(item.durationSeconds! / 60).ceil()}')),
      if (item.type == 'live_session' && !item.isLocked) l.itemOnWebsite,
    ].join(context.sep);
    final fg = item.isLocked ? c.inkTertiary : c.ink;
    // The bookmark is a picture; a screen reader hears "You are here".
    return MergeSemantics(
      child: Semantics(
        selected: current,
        value: current ? l.syllabusCurrent : null,
        child: Pressable(
          onTap: onTap,
          scale: 0.99,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.rule)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        context.digits('${item.position + 1}'),
                        textAlign: TextAlign.center,
                        style: a.type.title2.copyWith(
                          color: item.isDone ? c.inkTertiary : fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            textDirection: contentDirection(
                              context,
                              item.title,
                            ),
                            style: a.type.headline.copyWith(color: fg),
                          ),
                          Text(
                            meta,
                            style: a.type.footnote.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isDone)
                      Icon(
                        LucideIcons.circleCheck,
                        size: 22,
                        color: c.success,
                        semanticLabel: l.lessonDone,
                      )
                    else if (item.isLocked)
                      Icon(LucideIcons.lock, size: 20, color: c.inkTertiary)
                    else
                      Icon(
                        itemIcon(item.type),
                        size: 20,
                        color: current ? c.accent : c.inkSecondary,
                      ),
                  ],
                ),
              ),
              if (current)
                const PositionedDirectional(
                  start: 0,
                  top: -1,
                  child: Bookmark(width: 14, height: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tap on a locked item says why it is locked, instead of doing nothing.
void explainLocked(BuildContext context, SequenceItem item) {
  final why = lockText(context, item);
  if (why == null) return;
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(why)));
}
