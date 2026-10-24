import 'package:flutter/material.dart';

import "../atlas_theme.dart";

/// The academy's logo on a raised tile (logos are often transparent PNGs).
/// Without a logo, the first letter of the academy name in Readex Pro.
class AcademyLogo extends StatelessWidget {
  const AcademyLogo({
    super.key,
    required this.academyName,
    this.image,
    this.size = 40,
    this.background,
  });

  final String academyName;
  final ImageProvider? image;
  final double size;

  /// Defaults to raised. The picker uses the academy cover colour.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final bg = background ?? a.colors.raised;
    final fg =
        AcademyPalette.contrast(AcademyPalette.white, bg) >=
            AcademyPalette.contrast(AcademyPalette.ink, bg)
        ? AcademyPalette.white
        : AcademyPalette.ink;
    final letter = academyName.trim().isEmpty
        ? '·'
        : String.fromCharCode(academyName.trim().runes.first);
    return Semantics(
      image: true,
      label: academyName,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.26),
        ),
        alignment: Alignment.center,
        child: image != null
            ? Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: Image(
                  image: image!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, _, _) => _letter(a, letter, fg),
                ),
              )
            : _letter(a, letter, fg),
      ),
    );
  }

  Widget _letter(AtlasThemeAccess a, String letter, Color fg) => Text(
    letter.toUpperCase(),
    style: a.type.title2.copyWith(
      color: fg,
      fontSize: size * 0.45,
      height: 1,
      fontWeight: FontWeight.w700,
    ),
  );
}
