import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// The signature mark: a ribbon in the academy accent that shows where the
/// student stopped. Hangs from the top edge of the Continue panel, the
/// current syllabus row and the player header, at the leading side.
class Bookmark extends StatelessWidget {
  const Bookmark({super.key, this.width = 22, this.height = 38, this.color});

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _RibbonPainter(color ?? context.atlas.colors.accent),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final notch = h * 0.21;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - notch)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}
