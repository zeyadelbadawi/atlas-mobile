import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atlas_theme.dart';

/// A small gold moment around [child]: a burst of gold flecks and a light
/// tap, once, the first time it shows with [play] true. For passing a quiz,
/// finishing a course, or a new certificate. Under Reduce Motion only the
/// tap remains.
class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.child, this.play = true});
  final Widget child;
  final bool play;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  // The first 450 ms wait for the score ring to fill; the burst is an
  // interval of the animation rather than a timer.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1550),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: const Interval(450 / 1550, 1),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.play) return;
    _started = true;
    HapticFeedback.mediumImpact();
    if (!MediaQuery.disableAnimationsOf(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.atlas.colors.gold;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _t.value == 0 || _c.isCompleted
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      painter: _BurstPainter(t: _t.value, color: gold),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t, required this.color});
  final double t;
  final Color color;

  static const _count = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.shortestSide * 0.62;
    final out = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);
    final paint = Paint()..color = color.withValues(alpha: fade);
    for (var i = 0; i < _count; i++) {
      // Fixed angles and lengths so every run (and every golden) matches.
      final angle = (i / _count) * math.pi * 2 + (i.isEven ? 0.12 : -0.08);
      final len = reach * (0.75 + 0.25 * ((i * 7) % 5) / 4);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * len * out;
      final r = (i % 3 == 0 ? 4.0 : 2.6) * (1 - 0.4 * t);
      if (i % 3 == 1) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(angle + t * 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 2.6, height: r),
            Radius.circular(r / 2),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(p, r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}
