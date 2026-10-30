import 'package:flutter/material.dart';

import '../atlas_theme.dart';
import 'atlas_tab_shell.dart';

/// The tabs as a sidebar on wide screens (iPad, Android tablets), same four
/// sections as [AtlasTabBar]:
/// - iOS / iPadOS: a sidebar list, the selected row on the academy's tonal fill;
/// - Android: a Material 3 NavigationRail with labels.
class AtlasSidebar extends StatelessWidget {
  const AtlasSidebar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.header,
    this.platform,
  });

  final List<AtlasTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  /// Above the list on iOS (the academy's name).
  final Widget? header;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final p = platform ?? Theme.of(context).platform;
    final c = context.atlas.colors;
    final bar = p == TargetPlatform.iOS || p == TargetPlatform.macOS
        ? _SidebarList(
            tabs: tabs,
            index: index,
            onSelect: onSelect,
            header: header,
          )
        : _Rail(tabs: tabs, index: index, onSelect: onSelect);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sunken,
        border: BorderDirectional(end: BorderSide(color: c.rule)),
      ),
      child: bar,
    );
  }
}

Widget _icon(BuildContext context, AtlasTab t, Color color) {
  final c = context.atlas.colors;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(t.icon, size: 22, color: color),
      if (t.badge)
        PositionedDirectional(
          end: -2,
          top: -1,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              border: Border.all(color: c.sunken, width: 1.5),
            ),
          ),
        ),
    ],
  );
}

class _SidebarList extends StatelessWidget {
  const _SidebarList({
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.header,
  });
  final List<AtlasTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return SizedBox(
      width: AtlasSize.sidebarWidth,
      child: SafeArea(
        right: false,
        left: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                child: header,
              ),
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Semantics(
                  selected: i == index,
                  button: true,
                  label: tabs[i].label,
                  excludeSemantics: true,
                  child: Material(
                    color: i == index ? c.tonal : Colors.transparent,
                    borderRadius: BorderRadius.circular(AtlasRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AtlasRadius.md),
                      onTap: () => onSelect(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AtlasSize.touch,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _icon(
                                context,
                                tabs[i],
                                i == index ? c.accent : c.inkSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tabs[i].label,
                                  style: a.type.body.copyWith(
                                    color: i == index ? c.accent : c.ink,
                                    fontWeight: i == index
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.tabs,
    required this.index,
    required this.onSelect,
  });
  final List<AtlasTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return NavigationRail(
      backgroundColor: Colors.transparent,
      indicatorColor: c.tonal,
      selectedIndex: index,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.9,
      selectedLabelTextStyle: a.type.caption.copyWith(
        fontSize: 12,
        color: c.ink,
      ),
      unselectedLabelTextStyle: a.type.caption.copyWith(
        fontSize: 12,
        color: c.inkSecondary,
      ),
      destinations: [
        for (final t in tabs)
          NavigationRailDestination(
            icon: _icon(context, t, c.inkSecondary),
            selectedIcon: _icon(context, t, c.accent),
            label: Text(t.label),
          ),
      ],
    );
  }
}
