import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/ui_helpers.dart';
import '../../core/platform/app_settings.dart';
import '../../design/design.dart';

/// Scans an academy's QR code (its website address, or any page of it)
/// and returns the text to the academy picker. The camera runs only while
/// this screen is open; nothing is stored.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final value = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    _done = true;
    context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.qrTitle),
        actions: [
          IconButton(
            tooltip: l.qrTorch,
            icon: const Icon(LucideIcons.flashlight),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) {
          final denied =
              error.errorCode == MobileScannerErrorCode.permissionDenied;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    denied ? l.qrNoPermission : l.qrUnavailable,
                    textAlign: TextAlign.center,
                    style: a.type.body.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AtlasSpace.s20),
                  // A way out in both directions: allow the camera, or go
                  // back and type the name.
                  if (denied)
                    AtlasButton(
                      label: l.qrOpenSettings,
                      icon: LucideIcons.settings,
                      onPressed: openAppSettings,
                    ),
                  const SizedBox(height: AtlasSpace.s8),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(l.qrTypeInstead),
                  ),
                ],
              ),
            ),
          );
        },
        overlayBuilder: (context, constraints) =>
            ScanViewfinder(size: constraints.biggest, hint: l.qrHint),
      ),
    );
  }
}

/// The viewfinder: the camera dimmed outside a rounded window, gold corner
/// brackets, and a gold line sweeping the window (still under Reduce
/// Motion). The hint sits below in a pill.
class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key, required this.size, required this.hint});
  final Size size;
  final String hint;

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
      _sweep.value = 0.5;
    } else if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final side = widget.size.shortestSide * 0.68;
    final window = Rect.fromCenter(
      center: widget.size.center(Offset.zero),
      width: side,
      height: side,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) => CustomPaint(
              painter: _ViewfinderPainter(
                window: window,
                sweep: Curves.easeInOut.transform(_sweep.value),
              ),
            ),
          ),
        ),
        Positioned(
          left: AtlasSpace.gutter,
          right: AtlasSpace.gutter,
          top: window.bottom + AtlasSpace.s24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: a.type.subhead.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({required this.window, required this.sweep});
  final Rect window;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(window, const Radius.circular(24));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(r),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    // Corner brackets.
    final gold = Paint()
      ..color = AtlasBrand.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 28.0;
    const rad = 24.0;
    for (final (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final x = dx == 0 ? window.left : window.right;
      final y = dy == 0 ? window.top : window.bottom;
      final sx = dx == 0 ? 1.0 : -1.0;
      final sy = dy == 0 ? 1.0 : -1.0;
      canvas.drawPath(
        Path()
          ..moveTo(x, y + sy * (rad + arm))
          ..lineTo(x, y + sy * rad)
          ..arcToPoint(
            Offset(x + sx * rad, y),
            radius: const Radius.circular(rad),
            clockwise: sx * sy > 0,
          )
          ..lineTo(x + sx * (rad + arm), y),
        gold,
      );
    }
    // The sweeping line, fading at its ends.
    final y = window.top + 18 + (window.height - 36) * sweep;
    final line = Rect.fromLTWH(window.left + 16, y - 1, window.width - 32, 2);
    canvas.drawRect(
      line,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AtlasBrand.gold.withValues(alpha: 0),
            AtlasBrand.gold,
            AtlasBrand.gold.withValues(alpha: 0),
          ],
        ).createShader(line),
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) =>
      old.sweep != sweep || old.window != window;
}
