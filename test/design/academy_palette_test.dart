import 'dart:math';

import 'package:atlas_mobile/design/tokens/academy_palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the web identity format', () {
    final h = AcademyPalette.parseHsl('40 95% 54%')!;
    expect(h.hue, 40);
    expect(h.saturation, closeTo(0.95, 1e-9));
    expect(h.lightness, closeTo(0.54, 1e-9));
    expect(AcademyPalette.parseHsl('hsl(222, 72%, 46%)')!.hue, 222);
    expect(AcademyPalette.parseHsl('nope'), isNull);
    expect(AcademyPalette.fromHslString(null), same(AcademyPalette.atlas));
  });

  test('matches the values used in the Figma file', () {
    final z = AcademyPalette.fromHslString('40 95% 54%');
    expect(z.cover, const Color(0xFFF9AF1A));
    expect(z.onCover, AcademyPalette.ink);
    expect(z.accentLight, const Color(0xFF9A6804));
    final m = AcademyPalette.fromHslString('222 72% 46%');
    expect(m.onCover, AcademyPalette.white);
    expect(m.accentLight, const Color(0xFF2154CA));
  });

  test('every role passes AA for any academy colour', () {
    final rnd = Random(7);
    for (var i = 0; i < 2000; i++) {
      final p = AcademyPalette.derive(
        HSLColor.fromAHSL(
          1,
          rnd.nextDouble() * 360,
          rnd.nextDouble(),
          rnd.nextDouble(),
        ),
      );
      final c = AcademyPalette.contrast;
      expect(
        c(p.onCover, p.cover),
        greaterThanOrEqualTo(4.5),
        reason: '$i cover',
      );
      expect(
        c(p.onButtonLight, p.buttonLight),
        greaterThanOrEqualTo(4.5),
        reason: '$i button',
      );
      expect(
        c(p.onButtonDark, p.buttonDark),
        greaterThanOrEqualTo(4.5),
        reason: '$i button dark',
      );
      expect(
        c(p.accentLight, p.paperLight),
        greaterThanOrEqualTo(4.5),
        reason: '$i accent',
      );
      expect(
        c(p.accentDark, p.paperDark),
        greaterThanOrEqualTo(4.5),
        reason: '$i accent dark',
      );
    }
  });
}
