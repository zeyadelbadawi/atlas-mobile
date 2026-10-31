import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Atlas mark: the "A" with the open book (`assets/brand`, from the web's
/// `public/brand`). One colour, drawn at [size].
class AtlasMark extends StatelessWidget {
  const AtlasMark({super.key, this.size = 40, this.color});
  final double size;

  /// Defaults to the brand Navy.
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/brand/atlas-mark-white.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ?? const Color(0xFF1B398D),
      BlendMode.srcIn,
    ),
    semanticsLabel: 'Atlas',
  );
}

/// The "أطلس" / "Atlas" lettering on its own, in the reading language.
class AtlasWordmark extends StatelessWidget {
  const AtlasWordmark({super.key, this.height = 28, this.color});
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return SvgPicture.asset(
      ar
          ? 'assets/brand/atlas-wordmark-ar.svg'
          : 'assets/brand/atlas-wordmark-en.svg',
      height: height,
      colorFilter: ColorFilter.mode(
        color ?? const Color(0xFF141A29),
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    );
  }
}

/// Mark and lettering side by side, the mark at the reading start.
class AtlasLockup extends StatelessWidget {
  const AtlasLockup({
    super.key,
    this.height = 28,
    this.markColor,
    this.wordColor,
  });
  final double height;
  final Color? markColor;
  final Color? wordColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Atlas',
    container: true,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtlasMark(size: height * 1.15, color: markColor),
          SizedBox(width: height * 0.32),
          AtlasWordmark(height: height, color: wordColor),
        ],
      ),
    ),
  );
}
