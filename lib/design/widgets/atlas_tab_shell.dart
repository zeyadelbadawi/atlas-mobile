import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../atlas_theme.dart';

class AtlasTab {
  const AtlasTab({required this.icon, required this.label, this.badge = false});
  final IconData icon;
  final String label;

  /// Unseen items: a small accent dot on the icon.
  final bool badge;
}

/// Top-level navigation, native per platform with the same four sections:
/// - iOS / iPadOS: floating glass tab bar (iOS 26 shape) over the content;
/// - Android: Material 3 NavigationBar with the academy tonal indicator.
class AtlasTabBar extends StatelessWidget {
  const AtlasTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.platform,
  });

  final List<AtlasTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final p = platform ?? Theme.of(context).platform;
    return p == TargetPlatform.iOS || p == TargetPlatform.macOS
        ? _GlassBar(tabs: tabs, index: index, onSelect: onSelect)
        : _MaterialBar(tabs: tabs, index: index, onSelect: onSelect);
  }
}

Widget _icon(BuildContext context, AtlasTab t, Color color) {
  final c = context.atlas.colors;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(t.icon, size: 24, color: color),
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
              border: Border.all(color: c.raised, width: 1.5),
            ),
          ),
        ),
    ],
  );
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom - 6 : 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.raised.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: c.rule, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: Semantics(
                            selected: i == index,
                            button: true,
                            label: tabs[i].label,
                            excludeSemantics: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(i),
                              child: AnimatedContainer(
                                duration: AtlasMotion.quick,
                                curve: AtlasMotion.easeOut,
                                decoration: BoxDecoration(
                                  color: i == index
                                      ? c.tonal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _icon(
                                      context,
                                      tabs[i],
                                      i == index ? c.accent : c.ink,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tabs[i].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: a.type.tab.copyWith(
                                        color: i == index ? c.accent : c.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }
}

class _MaterialBar extends StatelessWidget {
  const _MaterialBar({
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
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: c.raised,
        indicatorColor: c.tonal,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => a.type.caption.copyWith(
            fontSize: 12,
            color: s.contains(WidgetState.selected) ? c.ink : c.inkSecondary,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.rule)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: _icon(context, t, c.inkSecondary),
                selectedIcon: _icon(context, t, c.accent),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}
