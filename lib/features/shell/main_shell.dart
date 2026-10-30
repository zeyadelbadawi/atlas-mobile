import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// The signed-in app: Home, My courses, Notifications (with an unread dot),
/// Account.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final tabs = [
      AtlasTab(icon: LucideIcons.house, label: l.tabHome),
      AtlasTab(icon: LucideIcons.bookOpen, label: l.tabCourses),
      AtlasTab(
        icon: LucideIcons.bell,
        label: l.tabNotifications,
        badge: unread > 0,
      ),
      AtlasTab(icon: LucideIcons.circleUser, label: l.tabAccount),
    ];
    void select(int i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex);

    // iPad and tablets: a sidebar. A phone, Slide Over or a narrow Split
    // View pane: the bottom tab bar.
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final from = ios ? AtlasSize.iosSidebarFrom : AtlasSize.sidebarFrom;
    if (MediaQuery.sizeOf(context).width >= from) {
      final academy = ref.watch(sessionProvider).academy;
      final a = context.atlas;
      return Scaffold(
        body: Row(
          children: [
            AtlasSidebar(
              tabs: tabs,
              index: shell.currentIndex,
              onSelect: select,
              header: academy == null
                  ? null
                  : Semantics(
                      header: true,
                      child: Text(
                        academy.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: a.type.title3.copyWith(color: a.colors.ink),
                      ),
                    ),
            ),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AtlasTabBar(
        index: shell.currentIndex,
        onSelect: select,
        tabs: tabs,
      ),
    );
  }
}
