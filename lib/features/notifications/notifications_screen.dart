import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../app/web_paths.dart';
import '../../core/notifications/notifications_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The notifications tab: the academy's feed (the same texts as the web),
/// newest first, unread marked, each opening the screen it is about. When
/// push is not on yet, a card explains what it is for before asking.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final feed = ref.watch(notificationFeedProvider);
    final hasUnread = feed.value?.items.any((n) => !n.isRead) ?? false;
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(notificationFeedProvider);
          ref.invalidate(unreadCountProvider);
          await ref.read(notificationFeedProvider.future);
        },
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) {
              ref.read(notificationFeedProvider.notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar.medium(
                title: Text(l.notificationsTitle),
                actions: [
                  if (hasUnread)
                    TextButton(
                      onPressed: () => ref
                          .read(notificationFeedProvider.notifier)
                          .markAllRead(),
                      child: Text(l.notificationsMarkAll),
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpace.gutter,
                  0,
                  AtlasSpace.gutter,
                  120,
                ),
                sliver: SliverToBoxAdapter(
                  child: ReadableWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PushCard(),
                        SettingsGroup(
                          children: [
                            SettingsRow(
                              title: l.announcementsTitle,
                              icon: LucideIcons.megaphone,
                              onTap: () => context.push('/announcements'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AtlasSpace.s8),
                        AsyncBody<NotificationPageState>(
                          value: feed,
                          onRetry: () =>
                              ref.invalidate(notificationFeedProvider),
                          data: (s) => s.items.isEmpty
                              ? _Empty(a: a)
                              : Column(
                                  children: [
                                    for (final (i, n) in s.items.indexed)
                                      Entrance(
                                        key: ValueKey(n.id),
                                        order: i,
                                        child: NotificationRow(notification: n),
                                      ),
                                    if (s.loadingMore)
                                      const Padding(
                                        padding: EdgeInsets.all(20),
                                        child:
                                            CircularProgressIndicator.adaptive(),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.a});
  final AtlasThemeAccess a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = a.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(LucideIcons.bellOff, size: 36, color: c.inkTertiary),
          const SizedBox(height: 12),
          Text(
            l.notificationsEmptyTitle,
            style: a.type.title3.copyWith(color: c.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l.notificationsEmptyBody,
            textAlign: TextAlign.center,
            style: a.type.subhead.copyWith(color: c.inkSecondary),
          ),
        ],
      ),
    );
  }
}

IconData notificationIcon(AppNotification n) {
  final key = n.titleKey;
  if (key.contains('announcement')) return LucideIcons.megaphone;
  if (key.contains('certificate')) return LucideIcons.award;
  if (key.contains('assignment')) return LucideIcons.fileText;
  if (key.contains('attempt') || key.contains('quiz')) {
    return LucideIcons.listChecks;
  }
  if (key.contains('device')) return LucideIcons.smartphone;
  if (key.contains('course') || key.contains('enrollment')) {
    return LucideIcons.bookOpen;
  }
  return switch (n.type) {
    'security' => LucideIcons.shieldCheck,
    'account' => LucideIcons.circleUser,
    'billing' => LucideIcons.receipt,
    _ => LucideIcons.bell,
  };
}

class NotificationRow extends ConsumerWidget {
  const NotificationRow({super.key, required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final n = notification;
    final catalog = ref.watch(notificationCatalogProvider);
    final lang = context.languageCode;
    final title =
        catalog.text(n.titleKey, lang, n.values, context.digits) ??
        l.notificationsTitle;
    final body =
        catalog.text(n.messageKey, lang, n.values, context.digits) ??
        l.notificationsFallback;
    return MergeSemantics(
      child: Pressable(
        scale: 0.99,
        onTap: () {
          ref.read(notificationFeedProvider.notifier).markRead(n);
          ref.read(analyticsProvider).event('notification_open', {
            'source': 'list',
          });
          context.push(appPathForWebLink(n.actionUrl));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n.isRead ? c.sunken : c.tonal,
                  borderRadius: BorderRadius.circular(AtlasRadius.md),
                ),
                child: Icon(
                  notificationIcon(n),
                  size: 20,
                  color: n.isRead ? c.inkSecondary : c.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: a.type.headline.copyWith(
                        color: c.ink,
                        fontWeight: n.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: a.type.subhead.copyWith(color: c.inkSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relative(context, n.createdAt),
                      style: a.type.caption.copyWith(color: c.inkTertiary),
                    ),
                  ],
                ),
              ),
              if (!n.isRead)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                  child: Semantics(
                    label: l.notificationsUnread,
                    child: Container(
                      width: 9,
                      height: 9,
                      // Gold: something new is one of the gold moments.
                      decoration: BoxDecoration(
                        color: c.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains what notifications are for, then asks — never at first launch
/// (Apple and Google both expect the request in context).
class PushCard extends ConsumerStatefulWidget {
  const PushCard({super.key});

  @override
  ConsumerState<PushCard> createState() => _PushCardState();
}

class _PushCardState extends ConsumerState<PushCard> {
  bool _dismissed = false, _asking = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final status = ref.watch(pushControllerProvider);
    if (status == PushStatus.denied) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AtlasSpace.s16),
        child: AtlasBanner(message: l.pushDenied),
      );
    }
    if (status != PushStatus.notAsked || _dismissed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpace.s16),
      child: Container(
        padding: const EdgeInsets.all(AtlasSpace.s16),
        decoration: BoxDecoration(
          color: c.tonal,
          borderRadius: BorderRadius.circular(AtlasRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bellRing, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.pushCardTitle,
                    style: a.type.headline.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(l.pushCardBody, style: a.type.subhead.copyWith(color: c.ink)),
            const SizedBox(height: 12),
            AtlasButton(
              label: l.pushCardAction,
              loading: _asking,
              onPressed: () async {
                setState(() => _asking = true);
                await ref
                    .read(pushControllerProvider.notifier)
                    .requestPermission();
                if (mounted) setState(() => _asking = false);
              },
            ),
            TextButton(
              onPressed: () => setState(() => _dismissed = true),
              child: Text(l.pushCardLater),
            ),
          ],
        ),
      ),
    );
  }
}
