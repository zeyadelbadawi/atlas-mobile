@Tags(['shots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/error_view.dart';
import 'package:atlas_mobile/design/design.dart';
import 'package:atlas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';

/// Where part of a screen fails to draw in a release build: Flutter's
/// grey box (before) and the app's note (after). Release-only, so drawn
/// side by side here rather than by forcing a real failure.
final _label = Platform.environment['SHOTS'];

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('error_part', (t) async {
    await setDevice(t, const Size(393, 520));
    final failed = _label == 'before'
        // Flutter's release ErrorWidget: a plain grey box.
        ? const ColoredBox(color: Color(0xF0C0C0C0), child: SizedBox.expand())
        : releaseErrorWidget(FlutterErrorDetails(exception: Exception()));
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildAtlasTheme(
          palette: AcademyPalette.atlas,
          brightness: Brightness.light,
          languageCode: 'ar',
          bodyFamily: testBodyFamily,
          bodyFallback: testBodyFallback,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'الرئيسية',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    key: const ValueKey('failed'),
                    height: 160,
                    child: failed,
                  ),
                  const SizedBox(height: 16),
                  const Text('باقي الصفحة شغال عادي.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    final r = t.getRect(find.byKey(const ValueKey('failed')));
    const k = 3.0;
    final dir = 'build/ux_shots/$_label';
    File('$dir/error_part.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode([r.left * k, r.top * k, r.right * k, r.bottom * k]),
      );
    await t.runAsync(() async {
      final image = await captureImage(t.element(find.byType(MaterialApp)));
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/error_part.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }, skip: _label == null);
}
