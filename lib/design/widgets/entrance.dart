import 'package:flutter/material.dart';

import '../tokens/atlas_metrics.dart';

/// Fades and lifts its child into place once, when it first appears.
/// [order] staggers siblings (each step 60 ms later, capped so a long list
/// never makes the last item wait). Nothing moves under Reduce Motion, and
/// the child is laid out at its final size from the first frame, so the
/// page never jumps.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.order = 0,
    this.offset = 14,
  });

  final Widget child;
  final int order;

  /// How far below its place the child starts, in logical pixels.
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _run = 420;

  // The stagger is part of the animation (an interval), not a timer, so a
  // list that rebuilds or leaves mid-way never leaves one pending.
  int get _delay => 60 * widget.order.clamp(0, 6);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _run + _delay),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay / (_run + _delay),
      1,
      curve: AtlasMotion.easeOut,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, widget.offset * (1 - _t.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}
