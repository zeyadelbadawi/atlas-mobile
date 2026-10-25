import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AtlasTabBar(
        index: shell.currentIndex,
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        tabs: [
          AtlasTab(icon: LucideIcons.house, label: l.tabHome),
          AtlasTab(icon: LucideIcons.bookOpen, label: l.tabCourses),
          AtlasTab(
            icon: LucideIcons.bell,
            label: l.tabNotifications,
            badge: unread > 0,
          ),
          AtlasTab(icon: LucideIcons.circleUser, label: l.tabAccount),
        ],
      ),
    );
  }
}
