import 'dart:io';

import 'package:atlas_mobile/core/clock.dart';
import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Body face in goldens: the app's own (Rubik and its subsets).
const testBodyFamily = 'Rubik';
const testBodyFallback = ['RubikArabic', 'RubikLatinExt'];

/// The moment every golden is drawn at: sample data is built relative to
/// it and the UI clock is frozen on it, so screenshots never drift.
final testNow = DateTime(2026, 10, 24, 10, 0);

bool _loaded = false;

Future<void> loadGoldenFonts() async {
  clockNow = () => testNow;
  if (_loaded) return;
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  Directory pkg(String name) => Directory(
    '${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}'
    '/hosted/pub.dev',
  ).listSync().whereType<Directory>().firstWhere((d) => d.path.contains('/$name-'));
  await load(
    'MaterialIcons',
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  await load(
    'packages/cupertino_icons/CupertinoIcons',
    '${pkg('cupertino_icons').path}/assets/CupertinoIcons.ttf',
  );
  final lucide =
      Directory(
        '${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}'
        '/hosted/pub.dev',
      ).listSync().whereType<Directory>().firstWhere(
        (d) => d.path.contains('lucide_icons_flutter-'),
      );
  await load('ReadexPro', 'assets/fonts/ReadexPro-Variable.ttf');
  await load('Rubik', 'assets/fonts/Rubik-Latin-Variable.ttf');
  await load('RubikArabic', 'assets/fonts/Rubik-Arabic-Variable.ttf');
  await load('RubikLatinExt', 'assets/fonts/Rubik-LatinExt-Variable.ttf');
  await load('NotoSansArabic', 'test/fonts/NotoSansArabic-Variable.ttf');
  await load('Inter', 'test/fonts/Inter-Variable.ttf');
  await load(
    'packages/lucide_icons_flutter/Lucide',
    '${lucide.path}/assets/lucide.ttf',
  );
  _loaded = true;
}

Widget goldenApp({
  required Widget child,
  required AcademyPalette palette,
  Brightness brightness = Brightness.light,
  String language = 'ar',
  TargetPlatform platform = TargetPlatform.iOS,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(language),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildAtlasTheme(
      palette: palette,
      brightness: brightness,
      languageCode: language,
      bodyFamily: testBodyFamily,
      bodyFallback: testBodyFallback,
      platform: platform,
    ),
    home: child,
  );
}

Future<void> setDevice(
  WidgetTester tester,
  Size size, {
  EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(
    top: padding.top * 3,
    bottom: padding.bottom * 3,
  );
  addTearDown(tester.view.reset);
}

/// A golden drawn as the device draws it: flutter_test strips shadow blur
/// (`debugDisableShadows`), which turns soft shadows into hard slabs. This
/// repaints with real shadows for the capture, then restores the default.
Future<void> expectGolden(
  WidgetTester tester,
  Finder finder,
  String file,
) async {
  debugDisableShadows = false;
  void dirty(RenderObject o) {
    o.markNeedsPaint();
    o.visitChildren(dirty);
  }

  for (final view in tester.binding.renderViews) {
    dirty(view);
  }
  await tester.pump();
  try {
    await expectLater(finder, matchesGoldenFile(file));
  } finally {
    debugDisableShadows = true;
  }
}
