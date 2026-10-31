import 'package:flutter/material.dart';

/// The type ramp, the Atlas brand's two faces (both cover Arabic and Latin,
/// both shipped by the web): Readex Pro for numbers and titles, Rubik for
/// body and controls. Sizes follow the user's text size (Dynamic Type /
/// font scale) like system text.
///
/// Arabic sets taller line heights than English; sizes are identical.
@immutable
class AtlasType extends ThemeExtension<AtlasType> {
  const AtlasType({
    required this.numeral,
    required this.largeTitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.headline,
    required this.body,
    required this.callout,
    required this.subhead,
    required this.footnote,
    required this.caption,
    required this.button,
    required this.tab,
  });

  /// [bodyFamily] is null in the app (platform face). Tests pass a bundled
  /// face so goldens render real glyphs.
  factory AtlasType.forLanguage(
    String languageCode, {
    String? bodyFamily,
    List<String>? bodyFallback,
  }) {
    final ar = languageCode == 'ar';
    TextStyle display(
      double size,
      double hAr,
      double hEn,
      int weight, {
      double trackingEn = 0,
    }) => TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      height: (ar ? hAr : hEn) / size,
      fontWeight: _weight(weight),
      fontVariations: [FontVariation.weight(weight.toDouble())],
      letterSpacing: ar ? 0 : trackingEn * size,
      leadingDistribution: TextLeadingDistribution.even,
    );
    TextStyle text(double size, double hAr, double hEn, int weight) =>
        TextStyle(
          fontFamily: bodyFamily,
          fontFamilyFallback: bodyFallback,
          fontSize: size,
          height: (ar ? hAr : hEn) / size,
          fontWeight: _weight(weight),
          fontVariations: [FontVariation.weight(weight.toDouble())],
          leadingDistribution: TextLeadingDistribution.even,
        );
    return AtlasType(
      numeral: display(
        44,
        52,
        48,
        600,
        trackingEn: -0.02,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      largeTitle: display(34, 46, 41, 700, trackingEn: -0.01),
      title1: display(28, 38, 34, 600, trackingEn: -0.005),
      title2: display(22, 32, 28, 600),
      title3: display(20, 30, 25, 500),
      headline: text(17, 28, 22, 600),
      body: text(17, 28, 22, 400),
      callout: text(16, 26, 21, 400),
      subhead: text(15, 24, 20, 400),
      footnote: text(13, 20, 18, 400),
      caption: text(12, 18, 16, 500),
      button: text(17, 24, 22, 600),
      tab: text(10, 14, 12, 500),
    );
  }

  static const String displayFamily = 'ReadexPro';
  static const String bodyFamily = 'Rubik';
  static const List<String> bodyFallback = ['RubikArabic', 'RubikLatinExt'];

  final TextStyle numeral;
  final TextStyle largeTitle;
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle callout;
  final TextStyle subhead;
  final TextStyle footnote;
  final TextStyle caption;
  final TextStyle button;
  final TextStyle tab;

  static FontWeight _weight(int w) => FontWeight.values.firstWhere(
    (f) => f.value == w,
    orElse: () => FontWeight.w400,
  );

  @override
  AtlasType copyWith() => this;

  @override
  AtlasType lerp(AtlasType? other, double t) => t < 0.5 ? this : other ?? this;
}
