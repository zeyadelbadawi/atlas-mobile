import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG AA (4.5:1) for every text colour on every surface it is drawn on,
/// for academy colours across the wheel (pale, saturated, dark) and both
/// themes. Computed from the tokens, not sampled from pixels: Flutter's
/// screenshot-based contrast check misreads small anti-aliased text.
void main() {
  const academies = {
    'atlas': null,
    'amber': '40 95% 54%',
    'navy': '222 72% 46%',
    'pink': '330 85% 65%',
    'lemon': '58 95% 70%',
    'green': '145 63% 42%',
    'black': '0 0% 5%',
    'white': '0 0% 98%',
  };

  for (final MapEntry(key: name, value: hsl) in academies.entries) {
    final palette = hsl == null
        ? AcademyPalette.atlas
        : AcademyPalette.fromHslString(hsl);
    for (final b in Brightness.values) {
      test('$name ${b.name}', () {
        final c = AtlasColors.of(palette, b);
        final failures = <String>[];
        void check(String what, Color fg, Color bg) {
          final r = AcademyPalette.contrast(fg, bg);
          if (r < 4.5) failures.add('$what: ${r.toStringAsFixed(2)}');
        }

        for (final (ground, g) in [
          ('paper', c.paper),
          ('raised', c.raised),
          ('sunken', c.sunken),
        ]) {
          check('ink on $ground', c.ink, g);
          check('inkSecondary on $ground', c.inkSecondary, g);
          check('inkTertiary on $ground', c.inkTertiary, g);
          check('accent on $ground', c.accent, g);
          check('danger on $ground', c.danger, g);
        }
        check('success on paper', c.success, c.paper);
        check('warning on paper', c.warning, c.paper);
        check('ink on tonal', c.ink, c.tonal);
        check('inkSecondary on tonal', c.inkSecondary, c.tonal);
        check('accent on tonal (tonal buttons)', c.accent, c.tonal);
        check('label on button', c.onButton, c.button);
        check('text on cover', c.onCover, c.cover);
        check('gold text on paper', c.goldText, c.paper);
        check('gold text on raised', c.goldText, c.raised);
        check('text on gold', c.onGold, c.gold);
        check('info on paper', c.info, c.paper);
        // Progress fill is a graphic: WCAG 1.4.11 asks 3:1 against the track.
        if (AcademyPalette.contrast(c.academy, c.raised) < 3) {
          failures.add('academy progress on raised');
        }
        expect(failures, isEmpty);
      });
    }
  }
}
