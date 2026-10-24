import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// The signed-in app: Home, My courses, Account. Notifications join in
/// phase 5 with push; no empty tab before then.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
          AtlasTab(icon: LucideIcons.circleUser, label: l.tabAccount),
        ],
      ),
    );
  }
}
