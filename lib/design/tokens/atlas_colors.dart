import 'package:flutter/material.dart';

import 'academy_palette.dart';

/// Semantic colours for one academy in one brightness. Mirrors the
/// `Theme · Light` / `Theme · Dark` variables in the Figma file.
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
    required this.cover,
    required this.onCover,
    required this.accent,
    required this.tonal,
    required this.button,
    required this.onButton,
    required this.coverIsLight,
  });

  factory AtlasColors.of(AcademyPalette p, Brightness brightness) {
    final light = brightness == Brightness.light;
    return AtlasColors(
      brightness: brightness,
      paper: light ? p.paperLight : p.paperDark,
      raised: light ? AcademyPalette.raisedLight : AcademyPalette.raisedDark,
      sunken: light ? AcademyPalette.sunkenLight : AcademyPalette.sunkenDark,
      ink: light ? const Color(0xFF121213) : const Color(0xFFF2F2EF),
      inkSecondary: light
          ? AcademyPalette.inkSecondaryLight
          : AcademyPalette.inkSecondaryDark,
      inkTertiary: light ? const Color(0xFF68686E) : const Color(0xFF96969C),
      rule: light ? const Color(0xFFE3E2DD) : const Color(0xFF33322F),
      ruleStrong: light ? const Color(0xFFC9C8C2) : const Color(0xFF4A4945),
      danger: light ? const Color(0xFFB3261E) : const Color(0xFFFF8A80),
      success: light ? const Color(0xFF1D6B35) : const Color(0xFF5FCB85),
      warning: light ? const Color(0xFF8A5A00) : const Color(0xFFF2B544),
      cover: p.cover,
      onCover: p.onCover,
      accent: light ? p.accentLight : p.accentDark,
      tonal: light ? p.tonalLight : p.tonalDark,
      button: light ? p.buttonLight : p.buttonDark,
      onButton: light ? p.onButtonLight : p.onButtonDark,
      coverIsLight: p.coverIsLight,
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
  final Color cover;
  final Color onCover;
  final Color accent;
  final Color tonal;
  final Color button;
  final Color onButton;
  final bool coverIsLight;

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
      cover: l(cover, other.cover),
      onCover: l(onCover, other.onCover),
      accent: l(accent, other.accent),
      tonal: l(tonal, other.tonal),
      button: l(button, other.button),
      onButton: l(onButton, other.onButton),
      coverIsLight: t < 0.5 ? coverIsLight : other.coverIsLight,
    );
  }
}
