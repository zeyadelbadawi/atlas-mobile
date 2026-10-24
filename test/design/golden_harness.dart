import 'dart:io';

import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Body face used in goldens instead of the platform font (which the test
/// engine does not have). The app itself uses the platform face.
const testBodyFamily = 'NotoSansArabic';
const testBodyFallback = ['Inter'];

bool _loaded = false;

Future<void> loadGoldenFonts() async {
  if (_loaded) return;
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  final lucide =
      Directory(
        '${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}'
        '/hosted/pub.dev',
      ).listSync().whereType<Directory>().firstWhere(
        (d) => d.path.contains('lucide_icons_flutter-'),
      );
  await load('ReadexPro', 'assets/fonts/ReadexPro-Variable.ttf');
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
