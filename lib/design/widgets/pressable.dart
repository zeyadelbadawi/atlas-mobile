import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/atlas_metrics.dart';

/// Touch feedback for every tappable Atlas surface: scales to 0.97 while
/// pressed (120ms strong ease-out) and returns on release. No ripple; the
/// scale is the feedback. Reduce Motion keeps the opacity dip only.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = false,
    this.scale = AtlasMotion.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedOpacity(
        opacity: _down && reduce ? 0.7 : 1,
        duration: AtlasMotion.press,
        child: AnimatedScale(
          scale: _down && !reduce ? widget.scale : 1,
          duration: AtlasMotion.press,
          curve: AtlasMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
