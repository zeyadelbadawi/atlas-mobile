import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../learning/course_widgets.dart';
import '../learning/learning_ui.dart';

/// One course: progress, where to continue, and the syllabus by unit with
/// the bookmark on the current item.
class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seq = ref.watch(sequenceProvider(courseId));
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(sequenceProvider(courseId));
          await ref.read(sequenceProvider(courseId).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtlasSpace.gutter,
            0,
            AtlasSpace.gutter,
            48,
          ),
          children: [
            ReadableWidth(
              child: AsyncBody<CourseSequence>(
                value: seq,
                onRetry: () => ref.invalidate(sequenceProvider(courseId)),
                data: (s) => _Course(s: s),
              ),
            ),
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
    final a = context.atlas;
    final next =
        s.continueItem ??
        s.items.where((i) => !i.isDone && !i.isLocked).firstOrNull;
    final left = minutesLeft(s);
    // Group by unit, keeping order.
    final units = <int, List<SequenceItem>>{};
    for (final i in s.items) {
      units.putIfAbsent(i.unitNumber, () => []).add(i);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.courseTitle,
            style: a.type.title1.copyWith(color: a.colors.ink),
          ),
        ),
        const SizedBox(height: AtlasSpace.s16),
        SegmentedProgress(segments: segmentsFor(s)),
        const SizedBox(height: AtlasSpace.s8),
        Row(
          children: [
            Text(
              l.countOf(
                context.digits('${s.completedCount}'),
                context.digits('${s.totalCount}'),
              ),
              style: a.type.caption.copyWith(color: a.colors.inkSecondary),
            ),
            const Spacer(),
            if (left != null)
              Text(
                l.minutesLeft(context.digits('$left')),
                style: a.type.caption.copyWith(color: a.colors.inkSecondary),
              ),
          ],
        ),
        const SizedBox(height: AtlasSpace.s20),
        if (s.finished)
          _CompletedCard(courseId: s.courseId)
        else if (next != null)
          AtlasButton(
            label: s.completedCount == 0 ? l.homeStart : l.courseContinue,
            icon: LucideIcons.play,
            onPressed: () => openItem(context, ref, s, next),
          ),
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
                  ? null
                  : () => openItem(context, ref, s, item),
            ),
        ],
      ],
    );
  }
}

class _CompletedCard extends ConsumerWidget {
  const _CompletedCard({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final completion = ref.watch(completionProvider(courseId)).value;
    final enabled = completion?.certificateEnabled ?? false;
    final issued = completion?.certificateStatus == 'issued';
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
    return MergeSemantics(
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
    );
  }
}
