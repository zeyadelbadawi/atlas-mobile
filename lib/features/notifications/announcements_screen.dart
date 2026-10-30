import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/notifications/notifications_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The academy's and the learner's courses' announcements, newest first.
/// On a wide screen (iPad) the open announcement sits beside the list.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final split = isSplit(context);
    final items = ref.watch(announcementsProvider).value;
    final open = _open ?? items?.firstOrNull?.id;
    final list = _list(context, split ? open : null);
    return Scaffold(
      appBar: AppBar(),
      body: !split
          ? list
          : SplitView(
              master: list,
              detail: open == null
                  ? const SizedBox.shrink()
                  : AnnouncementDetailScreen(
                      key: ValueKey(open),
                      id: open,
                      embedded: true,
                    ),
            ),
    );
  }

  void _select(String id) => isSplit(context)
      ? setState(() => _open = id)
      : context.push('/announcements/$id');

  Widget _list(BuildContext context, String? selected) {
    final l = context.l10n;
    final a = context.atlas;
    final value = ref.watch(announcementsProvider);
    return RefreshIndicator.adaptive(
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
                            for (final x in items)
                              _AnnouncementRow(
                                item: x,
                                selected: x.id == selected,
                                onTap: () => _select(x.id),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({
    required this.item,
    required this.onTap,
    this.selected = false,
  });
  final Announcement item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: Pressable(
          scale: 0.99,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: selected ? 10 : 0,
            ),
            decoration: BoxDecoration(
              color: selected ? c.tonal : null,
              borderRadius: selected
                  ? BorderRadius.circular(AtlasRadius.md)
                  : null,
              border: selected
                  ? null
                  : Border(bottom: BorderSide(color: c.rule)),
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
                Text(
                  item.title,
                  textDirection: contentDirection(context, item.title),
                  style: a.type.headline.copyWith(color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  textDirection: contentDirection(context, item.body),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: a.type.subhead.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    this.embedded = false,
  });
  final String id;

  /// Beside the list on iPad: no screen of its own, just the content.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final value = ref.watch(_announcementProvider(id));
    final content = ListView(
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
                    textDirection: contentDirection(context, x.title),
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
                  textDirection: contentDirection(context, x.body),
                  style: a.type.body.copyWith(color: c.ink),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (embedded) return content;
    return Scaffold(appBar: AppBar(), body: content);
  }
}

final _announcementProvider = FutureProvider.autoDispose
    .family<Announcement, String>(
      (ref, id) => ref.watch(notificationsRepositoryProvider).announcement(id),
    );
