import 'dart:io';

import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAtlasTheme(
    palette: AcademyPalette.atlas,
    brightness: Brightness.light,
    languageCode: 'en',
  ),
  home: Scaffold(body: Center(child: child)),
);

Color? _tile(WidgetTester t) {
  final box = t.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  return (box.decoration as BoxDecoration?)?.color;
}

Future<void> _load(WidgetTester t, String fixture) async {
  final logo = MemoryImage(File('test/fixtures/$fixture').readAsBytesSync());
  await t.pumpWidget(
    _host(AcademyLogo(academyName: 'Demo', image: logo, size: 64)),
  );
  // Decoding and measuring the logo happen off the test clock.
  for (var i = 0; i < 5; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUp(AcademyLogo.lightLogo.clear);

  testWidgets('a yellow logo gets the dark tile (more contrast than white)', (
    t,
  ) async {
    await _load(t, 'demo_logo.png');
    expect(_tile(t), AtlasBrand.navy900);
  });

  testWidgets('a dark logo sits on white', (t) async {
    await _load(t, 'dark_logo.png');
    expect(_tile(t), AcademyPalette.white);
  });

  testWidgets('a white logo gets a dark tile instead of vanishing', (t) async {
    await _load(t, 'white_logo.png');
    expect(_tile(t), AtlasBrand.navy900);
  });

  testWidgets('no logo: the first letter on the academy colour', (t) async {
    await t.pumpWidget(
      _host(const AcademyLogo(academyName: 'Ziadd', background: Colors.amber)),
    );
    expect(find.text('Z'), findsOneWidget);
  });
}
