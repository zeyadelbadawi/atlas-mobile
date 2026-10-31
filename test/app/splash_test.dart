@Tags(['golden'])
library;

import 'package:atlas_mobile/design/design.dart';
import 'package:atlas_mobile/features/system/splash_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';

/// The launch layer: the frames of its short animation, and that it leaves
/// once the app is ready (and not before its animation ends).
void main() {
  setUpAll(loadGoldenFonts);

  Future<void> pump(WidgetTester t, String lang, {required bool ready}) async {
    await setDevice(t, const Size(393, 852));
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SplashOverlay(
          ready: ready,
          child: const Scaffold(body: Center(child: Text('app'))),
        ),
      ),
    );
    // Let the SVGs decode (real asset I/O), then draw them.
    await t.runAsync(() async {
      for (final a in [
        'assets/brand/atlas-mark-white.svg',
        'assets/brand/atlas-wordmark-$lang.svg',
      ]) {
        final loader = SvgAssetLoader(a);
        await svg.cache.putIfAbsent(
          loader.cacheKey(null),
          () => loader.loadBytes(null),
        );
      }
    });
    await t.pump();
  }

  for (final lang in ['ar', 'en']) {
    testWidgets('splash frames $lang', (t) async {
      await pump(t, lang, ready: false);
      await expectLater(
        find.byType(SplashOverlay),
        matchesGoldenFile('goldens/splash_${lang}_0.png'),
      );
      await t.pump(const Duration(milliseconds: 380));
      await expectLater(
        find.byType(SplashOverlay),
        matchesGoldenFile('goldens/splash_${lang}_mid.png'),
      );
      await t.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(SplashOverlay),
        matchesGoldenFile('goldens/splash_${lang}_end.png'),
      );
    });
  }

  testWidgets('leaves once ready, after its animation', (t) async {
    await pump(t, 'ar', ready: true);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(AtlasMark), findsOneWidget, reason: 'still animating');
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(AtlasMark), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
