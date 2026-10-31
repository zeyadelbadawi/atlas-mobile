import 'package:flutter/material.dart';

import 'academy_palette.dart';

/// The Atlas brand palette (`atlas/src/index.css`, Royal Navy + Gold).
abstract final class AtlasBrand {
  static const navy50 = Color(0xFFF3F5FC);
  static const navy100 = Color(0xFFE2E8F9);
  static const navy200 = Color(0xFFC0CDF2);
  static const navy300 = Color(0xFF8AA2E5);
  static const navy400 = Color(0xFF4B6FD2);
  static const navy500 = Color(0xFF274BB0);
  static const navy600 = Color(0xFF1B398D);
  static const navy700 = Color(0xFF142D6C);
  static const navy800 = Color(0xFF102251);
  static const navy900 = Color(0xFF0C1936);
  static const gold = Color(0xFFE0A424);
  static const goldOnLight = Color(0xFF8A5A00);
  static const goldOnDark = Color(0xFFF0BF4C);
  static const onGold = Color(0xFF1B1303);
  static const primaryDark = Color(0xFF709DFF);
  static const onPrimaryDark = Color(0xFF07132F);
}

/// Semantic colours in one brightness. The app is built on Atlas's own
/// palette (Navy for actions, links and selection; Gold for the moments
/// that matter: where you stopped, a pass, a certificate). The academy's
/// colour is the [cover] (the band behind the large title, course covers)
/// and [academy] (progress), corrected for contrast.
@immutable
class AtlasColors extends ThemeExtension<AtlasColors> {
  const AtlasColors({
    required this.brightness,
    required this.paper,
    required this.raised,
    required this.sunken,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.rule,
    required this.ruleStrong,
    required this.danger,
    required this.success,
    required this.warning,
    required this.info,
    required this.cover,
    required this.onCover,
    required this.accent,
    required this.tonal,
    required this.button,
    required this.onButton,
    required this.coverIsLight,
    required this.academy,
    required this.gold,
    required this.goldText,
    required this.onGold,
    required this.shadow,
  });

  factory AtlasColors.of(AcademyPalette p, Brightness brightness) {
    final light = brightness == Brightness.light;
    return AtlasColors(
      brightness: brightness,
      paper: light ? const Color(0xFFFCFCFD) : const Color(0xFF0E121B),
      raised: light ? AcademyPalette.raisedLight : AcademyPalette.raisedDark,
      sunken: light ? AcademyPalette.sunkenLight : AcademyPalette.sunkenDark,
      ink: light ? const Color(0xFF141A29) : const Color(0xFFECEEF3),
      inkSecondary: light
          ? AcademyPalette.inkSecondaryLight
          : AcademyPalette.inkSecondaryDark,
      inkTertiary: light ? const Color(0xFF606A7E) : const Color(0xFF8E95A7),
      rule: light ? const Color(0xFFE4E7EE) : const Color(0xFF242A38),
      ruleStrong: light ? const Color(0xFFC9CEDA) : const Color(0xFF363D4E),
      danger: light ? const Color(0xFFC3282D) : const Color(0xFFF2787C),
      success: light ? const Color(0xFF267E55) : const Color(0xFF4CBF86),
      warning: light ? AtlasBrand.goldOnLight : AtlasBrand.goldOnDark,
      info: light ? const Color(0xFF2762A5) : const Color(0xFF6FA6E8),
      cover: p.cover,
      onCover: p.onCover,
      accent: light ? AtlasBrand.navy600 : AtlasBrand.primaryDark,
      tonal: light ? const Color(0xFFE8EDFA) : const Color(0xFF1C2A4F),
      button: light ? AtlasBrand.navy600 : AtlasBrand.primaryDark,
      onButton: light ? const Color(0xFFFFFFFF) : AtlasBrand.onPrimaryDark,
      coverIsLight: p.coverIsLight,
      academy: light ? p.accentLight : p.accentDark,
      gold: AtlasBrand.gold,
      goldText: light ? AtlasBrand.goldOnLight : AtlasBrand.goldOnDark,
      onGold: AtlasBrand.onGold,
      shadow: light ? const Color(0x14141A29) : const Color(0x66000000),
    );
  }

  final Brightness brightness;
  final Color paper;
  final Color raised;
  final Color sunken;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color rule;
  final Color ruleStrong;
  final Color danger;
  final Color success;
  final Color warning;
  final Color info;
  final Color cover;
  final Color onCover;
  final Color accent;
  final Color tonal;
  final Color button;
  final Color onButton;
  final bool coverIsLight;

  /// The academy's own colour as text/graphic on the paper (progress).
  final Color academy;

  /// Gold fill (bookmark, badges) and its readable text forms.
  final Color gold;
  final Color goldText;
  final Color onGold;

  /// Soft card shadow colour.
  final Color shadow;

  @override
  AtlasColors copyWith() => this;

  @override
  AtlasColors lerp(AtlasColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtlasColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      paper: l(paper, other.paper),
      raised: l(raised, other.raised),
      sunken: l(sunken, other.sunken),
      ink: l(ink, other.ink),
      inkSecondary: l(inkSecondary, other.inkSecondary),
      inkTertiary: l(inkTertiary, other.inkTertiary),
      rule: l(rule, other.rule),
      ruleStrong: l(ruleStrong, other.ruleStrong),
      danger: l(danger, other.danger),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      cover: l(cover, other.cover),
      onCover: l(onCover, other.onCover),
      accent: l(accent, other.accent),
      tonal: l(tonal, other.tonal),
      button: l(button, other.button),
      onButton: l(onButton, other.onButton),
      coverIsLight: t < 0.5 ? coverIsLight : other.coverIsLight,
      academy: l(academy, other.academy),
      gold: l(gold, other.gold),
      goldText: l(goldText, other.goldText),
      onGold: l(onGold, other.onGold),
      shadow: l(shadow, other.shadow),
    );
  }
}
