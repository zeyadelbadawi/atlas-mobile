import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// A score as a ring that fills from the top, with [child] (the number) in
/// the middle. The fill runs once when it first shows; under Reduce Motion
/// it is drawn full at once.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 128,
    this.stroke = 10,
    this.color,
    this.track,
  });

  /// 0..1.
  final double value;
  final Widget child;
  final double size;
  final double stroke;

  /// Defaults to the brand accent on a hairline track.
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    final target = value.clamp(0.0, 1.0);
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? target : 0, end: target),
        duration: still ? Duration.zero : const Duration(milliseconds: 900),
        curve: AtlasMotion.easeOut,
        builder: (context, t, child) => CustomPaint(
          painter: _RingPainter(
            value: t,
            stroke: stroke,
            color: color ?? c.accent,
            track: track ?? c.rule,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
    required this.rtl,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (value <= 0) return;
    // Clockwise in LTR, counter-clockwise in RTL: it fills the way the
    // learner reads.
    final sweep = math.pi * 2 * value * (rtl ? -1 : 1);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, base..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.rtl != rtl;
}
