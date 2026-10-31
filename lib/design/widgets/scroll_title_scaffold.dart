import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// A page whose name is a large title in its content. Once that title has
/// scrolled away, the name eases into the top bar, so the learner always
/// knows which page they are on (Krug's trunk test). Like iOS large titles.
class ScrollTitleScaffold extends StatefulWidget {
  const ScrollTitleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showAfter = 40,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  /// Empty while the page does not know its name yet (still loading).
  final String title;
  final Widget body;

  /// Scroll offset by which the large title has gone under the bar: about
  /// its own height when it opens the page; more with an icon above it.
  final double showAfter;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  State<ScrollTitleScaffold> createState() => _ScrollTitleScaffoldState();
}

class _ScrollTitleScaffoldState extends State<ScrollTitleScaffold> {
  bool _shown = false;

  bool _onScroll(ScrollUpdateNotification n) {
    if (n.metrics.axis == Axis.vertical) {
      final shown = n.metrics.pixels > widget.showAfter;
      if (shown != _shown) setState(() => _shown = shown);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.backgroundColor,
    appBar: AppBar(
      // Opacity 0 also takes the title out of the screen reader's way: the
      // large title already says it.
      title: AnimatedOpacity(
        opacity: _shown && widget.title.isNotEmpty ? 1 : 0,
        duration: AtlasMotion.quick,
        child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ),
    body: NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: widget.body,
    ),
    bottomNavigationBar: widget.bottomNavigationBar,
  );
}
