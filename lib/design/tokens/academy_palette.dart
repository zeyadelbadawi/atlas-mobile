import 'package:flutter/painting.dart';

/// The colours an academy contributes to the app, derived from the one
/// colour it chose on the web (`primaryColor`, an HSL string such as
/// `"40 95% 54%"` from `GET /public/websites/:id/identity`).
///
/// Academies can pick anything, including colours that fail contrast, so
/// every role here is corrected until it passes WCAG AA:
/// - text on the cover band: black or white, whichever is stronger;
/// - accent (links, icons, the bookmark): the hue darkened (light mode) or
///   lightened (dark mode) until it reaches 4.5:1 on the paper;
/// - buttons: the cover colour when its label passes 4.5:1, otherwise the
///   corrected accent.
///
/// Same algorithm as `docs/design/academy_colors.py`, which produced the
/// values in the Figma file.
class AcademyPalette {
  const AcademyPalette({
    required this.cover,
    required this.onCover,
    required this.paperLight,
    required this.paperDark,
    required this.accentLight,
    required this.accentDark,
    required this.tonalLight,
    required this.tonalDark,
    required this.buttonLight,
    required this.onButtonLight,
    required this.buttonDark,
    required this.onButtonDark,
  });

  /// Builds the palette from the academy's `primaryColor`. Falls back to
  /// [atlas] when the value cannot be parsed.
  factory AcademyPalette.fromHslString(String? value) {
    final hsl = parseHsl(value);
    if (hsl == null) return atlas;
    return AcademyPalette.derive(hsl);
  }

  factory AcademyPalette.derive(HSLColor primary) {
    // Cover: the academy colour, nudged only when neither black nor white
    // text reaches 4.5:1 on it.
    final (p, onCover) = _readable(primary.withAlpha(1));
    final paperLight = _mix(_paper, p, 0.035);
    final paperDark = _mix(_night, p, 0.07);

    // The tinted fill (cards, secondary buttons): as strong as it can be
    // while secondary text on it still reaches 4.5:1. Pale academy colours
    // get a lighter tint in dark mode.
    final tonalLight = _tint(paperLight, p, 0.14, inkSecondaryLight);
    final tonalDark = _tint(paperDark, p, 0.24, inkSecondaryDark);
    // The accent is text on every surface: the paper, cards, fields and the
    // tonal fill of secondary buttons. It must pass on the hardest of them.
    final accentLight = _towardContrast(primary, [
      paperLight,
      raisedLight,
      sunkenLight,
      tonalLight,
    ], darken: true);
    final accentDark = _towardContrast(primary, [
      paperDark,
      raisedDark,
      sunkenDark,
      tonalDark,
    ], darken: false);

    final (buttonLight, onButtonLight) = _readable(HSLColor.fromColor(p));
    final (buttonDark, onButtonDark) = _readable(HSLColor.fromColor(p));

    return AcademyPalette(
      cover: p,
      onCover: onCover,
      paperLight: paperLight,
      paperDark: paperDark,
      accentLight: accentLight,
      accentDark: accentDark,
      tonalLight: tonalLight,
      tonalDark: tonalDark,
      buttonLight: buttonLight,
      onButtonLight: onButtonLight,
      buttonDark: buttonDark,
      onButtonDark: onButtonDark,
    );
  }

  /// A fill and the stronger of white/ink on it, with the fill's lightness
  /// moved away from the text colour until the pair reaches 4.5:1.
  static (Color, Color) _readable(HSLColor fill) {
    var c = fill.toColor();
    var fg = _strongerOf(white, ink, on: c);
    var l = fill.lightness;
    while (contrast(fg, c) < 4.5 && l > 0 && l < 1) {
      l = (fg == white ? l - 0.01 : l + 0.01).clamp(0.0, 1.0);
      c = fill.withLightness(l).toColor();
      fg = _strongerOf(white, ink, on: c);
    }
    return (c, fg);
  }

  /// Atlas's own cover (Navy 600): the academy picker, first-run and
  /// About screens, where no academy has been chosen yet.
  static final AcademyPalette atlas = AcademyPalette.derive(
    HSLColor.fromColor(const Color(0xFF1B398D)),
  );

  final Color cover;
  final Color onCover;
  final Color paperLight;
  final Color paperDark;
  final Color accentLight;
  final Color accentDark;
  final Color tonalLight;
  final Color tonalDark;
  final Color buttonLight;
  final Color onButtonLight;
  final Color buttonDark;
  final Color onButtonDark;

  /// True when the cover is light enough that the status bar and cover text
  /// are drawn dark (e.g. Ziadd's amber).
  bool get coverIsLight => onCover == ink;

  /// Card and field surfaces (shared with [AtlasColors]).
  static const Color raisedLight = Color(0xFFFFFFFF);
  static const Color raisedDark = Color(0xFF161B27);
  static const Color sunkenLight = Color(0xFFF1F3F7);
  static const Color sunkenDark = Color(0xFF1E2433);

  /// Secondary text (shared with [AtlasColors]).
  static const Color inkSecondaryLight = Color(0xFF5C657A);
  static const Color inkSecondaryDark = Color(0xFF9CA3B4);

  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF141A29);
  static const Color _paper = Color(0xFFFCFCFD);
  static const Color _night = Color(0xFF0E121B);

  /// Parses `"222 72% 46%"` (the web's CSS-variable format), with or without
  /// commas, `hsl(...)` or percent signs.
  static HSLColor? parseHsl(String? value) {
    if (value == null) return null;
    final numbers = RegExp(r'-?\d+(\.\d+)?')
        .allMatches(value)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    if (numbers.length < 3) return null;
    final h = numbers[0] % 360;
    final s = (numbers[1] / 100).clamp(0.0, 1.0);
    final l = (numbers[2] / 100).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(1, h < 0 ? h + 360 : h, s, l);
  }

  /// WCAG 2.x contrast ratio.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static Color _strongerOf(Color a, Color b, {required Color on}) =>
      contrast(a, on) >= contrast(b, on) ? a : b;

  static Color _towardContrast(
    HSLColor start,
    List<Color> grounds, {
    required bool darken,
  }) {
    var l = start.lightness;
    var c = start.toColor();
    while (grounds.any((g) => contrast(c, g) < 4.5)) {
      l = darken ? l - 0.01 : l + 0.01;
      if (l < 0 || l > 1) {
        // The hue cannot reach 4.5:1 on this ground; use plain ink.
        return darken ? ink : white;
      }
      c = start.withLightness(l).toColor();
    }
    return c;
  }

  static Color _tint(Color ground, Color colour, double most, Color text) {
    var t = most;
    var c = _mix(ground, colour, t);
    while (t > 0 && contrast(text, c) < 4.5) {
      t -= 0.01;
      c = _mix(ground, colour, t < 0 ? 0 : t);
    }
    return c;
  }

  static Color _mix(Color a, Color b, double t) => Color.from(
    alpha: 1,
    red: a.r + (b.r - a.r) * t,
    green: a.g + (b.g - a.g) * t,
    blue: a.b + (b.b - a.b) * t,
  );
}
