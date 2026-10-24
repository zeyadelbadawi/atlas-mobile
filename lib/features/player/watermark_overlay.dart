import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The forensic watermark drawn over every video the app plays.
///
/// Same rules as the web player (`ForensicWatermarkFrame.tsx`) and the
/// backend contract (`docs/FORENSIC_WATERMARK.md`):
///
/// 1. a readable label — the viewer's code plus a masked hint of their
///    account — that jumps to a new random spot every 20–45 s, dimming for
///    350 ms while it moves;
/// 2. a very faint tile of the code, rotated −24°, 280×160 px, that drifts
///    one tile every 90 s, so cropping or blurring the label still leaves the
///    code across the picture.
///
/// It never takes touches (the player's controls stay usable) and is hidden
/// from screen readers; the caption under the player explains it.
/// With "reduce motion" on, the tile does not drift and the label jumps
/// without the fade.
class WatermarkOverlay extends StatefulWidget {
  const WatermarkOverlay({
    super.key,
    required this.code,
    this.secondary,
    this.random,
  });

  /// `watermark.code` from the lesson grant, e.g. `6SG7A-QKN29`.
  final String code;

  /// `watermark.maskedIdentity`, e.g. `g•••@example.test`.
  final String? secondary;

  /// For tests.
  final math.Random? random;

  static const moveMin = Duration(seconds: 20);
  static const moveSpread = Duration(seconds: 25);
  static const fade = Duration(milliseconds: 350);
  static const tileSize = Size(280, 160);
  static const driftPeriod = Duration(seconds: 90);

  @override
  State<WatermarkOverlay> createState() => _WatermarkOverlayState();
}

class _WatermarkOverlayState extends State<WatermarkOverlay>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: WatermarkOverlay.driftPeriod,
  );
  late Offset _position = _nextPosition(null);
  bool _moving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  /// Fractions of the stage (inline start, top), anywhere the label fits,
  /// and visibly somewhere else than before — same ranges as the web.
  Offset _nextPosition(Offset? previous) {
    Offset draw() => Offset(
      0.04 + _random.nextDouble() * 0.58,
      0.06 + _random.nextDouble() * 0.74,
    );
    for (var i = 0; i < 6; i++) {
      final next = draw();
      if (previous == null ||
          (next.dx - previous.dx).abs() + (next.dy - previous.dy).abs() >
              0.30) {
        return next;
      }
    }
    return draw();
  }

  void _schedule() {
    final wait =
        WatermarkOverlay.moveMin +
        WatermarkOverlay.moveSpread * _random.nextDouble();
    _timer = Timer(wait, () {
      if (!mounted) return;
      setState(() => _moving = true);
      _timer = Timer(WatermarkOverlay.fade, () {
        if (!mounted) return;
        setState(() {
          _position = _nextPosition(_position);
          _moving = false;
        });
        _schedule();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final label = widget.secondary == null || widget.secondary!.isEmpty
        ? widget.code
        : '${widget.code} · ${widget.secondary}';

    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = (constraints.maxWidth * 0.012).clamp(10.0, 18.0);
            return Stack(
              key: const ValueKey('forensic-watermark'),
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) => CustomPaint(
                    key: const ValueKey('forensic-watermark-pattern'),
                    painter: _PatternPainter(
                      text: widget.code,
                      progress: reduceMotion ? 0 : _drift.value,
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: _position.dx * constraints.maxWidth,
                  top: _position.dy * constraints.maxHeight,
                  child: AnimatedOpacity(
                    key: const ValueKey('forensic-watermark-label'),
                    opacity: _moving ? 0.4 : 1,
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    child: Text(
                      label,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Menlo', 'Courier'],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontSize: fontSize,
                        color: Colors.white.withValues(alpha: 0.6),
                        shadows: const [
                          Shadow(blurRadius: 2, color: Color(0xBF000000)),
                          Shadow(blurRadius: 1, color: Color(0xE6000000)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.text, required this.progress});

  final String text;

  /// 0..1 through one drift period: the tile slides one tile right and down.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const tile = WatermarkOverlay.tileSize;
    final fill = TextPainter(
      text: TextSpan(
        text: text.length > 48 ? text.substring(0, 48) : text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: Colors.white.withValues(alpha: 0.075),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = progress * tile.width;
    final dy = progress * tile.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (
      var y = -tile.height + dy;
      y < size.height + tile.height;
      y += tile.height
    ) {
      for (
        var x = -tile.width + dx;
        x < size.width + tile.width;
        x += tile.width
      ) {
        canvas.save();
        canvas.translate(x + tile.width / 2, y + tile.height / 2);
        canvas.rotate(-24 * math.pi / 180);
        fill.paint(canvas, Offset(-fill.width / 2, -fill.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.progress != progress || old.text != text;
}
