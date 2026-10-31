@Tags(['golden'])
library;

import 'package:atlas_mobile/design/design.dart';
import 'package:atlas_mobile/design/gallery/design_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

const iphone = Size(393, 852);

void main() {
  setUpAll(loadGoldenFonts);

  final ziadd = AcademyPalette.fromHslString('40 95% 54%');
  final manara = AcademyPalette.fromHslString('222 72% 46%');
  final riwaq = AcademyPalette.fromHslString('199 64% 30%');

  final cases = <String, Widget Function()>{
    'home_ziadd_light_ar_ios': () => goldenApp(
      palette: ziadd,
      child: const HomeSample(academyName: 'أكاديمية زياد'),
    ),
    'home_ziadd_dark_ar_ios': () => goldenApp(
      palette: ziadd,
      brightness: Brightness.dark,
      child: const HomeSample(academyName: 'أكاديمية زياد'),
    ),
    'home_manara_light_ar_android': () => goldenApp(
      palette: manara,
      platform: TargetPlatform.android,
      child: const HomeSample(
        academyName: 'منارة',
        platform: TargetPlatform.android,
      ),
    ),
    'home_riwaq_light_en_ios': () => goldenApp(
      palette: riwaq,
      language: 'en',
      child: const HomeSample(academyName: 'Riwaq Academy'),
    ),
    'signin_ziadd_light_ar': () => goldenApp(
      palette: ziadd,
      child: const SignInSample(
        academyName: 'أكاديمية زياد',
        host: 'ziadd.atlass.dpdns.org',
      ),
    ),
    'signin_manara_dark_en': () => goldenApp(
      palette: manara,
      brightness: Brightness.dark,
      language: 'en',
      child: const SignInSample(
        academyName: 'Manara',
        host: 'manara.atlass.dpdns.org',
      ),
    ),
  };

  for (final entry in cases.entries) {
    testWidgets(entry.key, (tester) async {
      await setDevice(
        tester,
        entry.key.startsWith('signin') ? const Size(393, 1500) : iphone,
      );
      await tester.pumpWidget(entry.value());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectGolden(
        tester,
        find.byType(MaterialApp),
        'goldens/${entry.key}.png',
      );
    });
  }
}
