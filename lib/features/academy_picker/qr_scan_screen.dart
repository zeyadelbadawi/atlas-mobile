import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/ui_helpers.dart';
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
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AtlasSpace.gutter),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? l.qrNoPermission
                  : l.qrUnavailable,
              textAlign: TextAlign.center,
              style: a.type.body.copyWith(color: Colors.white),
            ),
          ),
        ),
        overlayBuilder: (context, constraints) {
          final side = constraints.biggest.shortestSide * 0.66;
          return Stack(
            children: [
              Center(
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(AtlasRadius.xl),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.82),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpace.gutter,
                  ),
                  child: Text(
                    l.qrHint,
                    textAlign: TextAlign.center,
                    style: a.type.body.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
