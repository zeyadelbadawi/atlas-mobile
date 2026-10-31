import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';

/// The animated half of the launch screen. It opens on exactly the frame
/// the native launch screen shows (the white mark centred on Navy 600), then
/// the mark settles up, the lettering rises in under it and a gold rule
/// draws beneath, and the whole layer fades away once the app is [ready]
/// (the session is restored). About 0.8 s; never waits longer than the app.
/// Under Reduce Motion it shows the final frame and only fades.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.ready, required this.child});

  final bool ready;
  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  bool _gone = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
    _intro.addStatusListener((_) => _maybeLeave());
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _gone = true);
      }
    });
    _maybeLeave();
  }

  @override
  void didUpdateWidget(SplashOverlay old) {
    super.didUpdateWidget(old);
    _maybeLeave();
  }

  void _maybeLeave() {
    if (widget.ready && _intro.isCompleted && !_exit.isAnimating) {
      _exit.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: _exit.isCompleted,
          child: FadeTransition(
            opacity: ReverseAnimation(
              CurvedAnimation(parent: _exit, curve: Curves.easeOut),
            ),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: ColoredBox(
                color: AtlasBrand.navy600,
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) => _Frame(t: _intro.value),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    double seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
        c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
    final settle = seg(0, 0.5);
    final word = seg(0.25, 0.75);
    final rule = seg(0.45, 1);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Starts as the native frame: 120 at the centre.
          Transform.translate(
            offset: Offset(0, 54 * (1 - settle) - 6),
            child: AtlasMark(size: 120 - 36 * settle, color: Colors.white),
          ),
          SizedBox(height: 18 * settle),
          Opacity(
            opacity: word,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - word)),
              child: const AtlasWordmark(height: 34, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 44 * rule,
            height: 3,
            decoration: BoxDecoration(
              color: AtlasBrand.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
