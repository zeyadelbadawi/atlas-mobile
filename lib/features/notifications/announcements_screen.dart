import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/notifications/notifications_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The academy's and the learner's courses' announcements, newest first.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final value = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(announcementsProvider.future),
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
                      l.announcementsTitle,
                      style: a.type.title1.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s12),
                  AsyncBody<List<Announcement>>(
                    value: value,
                    onRetry: () => ref.invalidate(announcementsProvider),
                    data: (items) => items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              l.announcementsEmpty,
                              textAlign: TextAlign.center,
                              style: a.type.subhead.copyWith(
                                color: a.colors.inkSecondary,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final x in items) _AnnouncementRow(item: x),
                            ],
                          ),
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

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Pressable(
        scale: 0.99,
        onTap: () => context.push('/announcements/${item.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  item.audience == 'course'
                      ? l.announcementCourse
                      : l.announcementAcademy,
                  if (item.publishedAt != null)
                    shortDate(context, item.publishedAt!),
                ].join(context.sep),
                style: a.type.caption.copyWith(color: c.accent),
              ),
              const SizedBox(height: 2),
              Text(item.title, style: a.type.headline.copyWith(color: c.ink)),
              const SizedBox(height: 2),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: a.type.subhead.copyWith(color: c.inkSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final value = ref.watch(_announcementProvider(id));
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
            child: AsyncBody<Announcement>(
              value: value,
              onRetry: () => ref.invalidate(_announcementProvider(id)),
              data: (x) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [
                      x.audience == 'course'
                          ? l.announcementCourse
                          : l.announcementAcademy,
                      if (x.publishedAt != null)
                        shortDate(context, x.publishedAt!),
                    ].join(context.sep),
                    style: a.type.footnote.copyWith(color: c.accent),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      x.title,
                      style: a.type.title1.copyWith(color: c.ink),
                    ),
                  ),
                  if (x.authorName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.announcementBy(x.authorName),
                      style: a.type.subhead.copyWith(color: c.inkSecondary),
                    ),
                  ],
                  const SizedBox(height: AtlasSpace.s16),
                  SelectableText(
                    x.body,
                    style: a.type.body.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _announcementProvider = FutureProvider.autoDispose
    .family<Announcement, String>(
      (ref, id) => ref.watch(notificationsRepositoryProvider).announcement(id),
    );
