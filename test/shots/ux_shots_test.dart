@Tags(['shots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

/// Before/after pictures of a UX change, for review in chat:
///
///   SHOTS=before flutter test --tags shots test/shots   (on the old code)
///   SHOTS=after  flutter test --tags shots test/shots   (on the new code)
///
/// Writes `build/ux_shots/<before|after>/<name>.png` (not committed).
final _label = Platform.environment['SHOTS'];

Future<void> _save(WidgetTester t, String name) async {
  debugDisableShadows = false;
  void dirty(RenderObject o) {
    o.markNeedsPaint();
    o.visitChildren(dirty);
  }

  for (final v in t.binding.renderViews) {
    dirty(v);
  }
  // Let fades and implicit animations finish before the picture.
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
  final element = t.element(find.byType(AtlasApp));
  await t.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/ux_shots/$_label/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

void shot(String name, Future<void> Function(WidgetTester) arrange) =>
    testWidgets(name, (t) async {
      await arrange(t);
      await _save(t, name);
    }, skip: _label == null);

void main() {
  setUpAll(loadGoldenFonts);

  shot('results_scrolled', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/results',
      size: const Size(393, 700),
    );
    await t.drag(find.byType(ListView).first, const Offset(0, -300));
    await t.pump(const Duration(milliseconds: 400));
  });

  shot('profile_scrolled', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/profile',
      size: const Size(393, 700),
    );
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump(const Duration(milliseconds: 400));
  });

  shot('picker_removed_recent', (t) async {
    await pumpScreen(t, session: AsNoAcademy.new, size: const Size(393, 1100));
    await t.drag(find.text('Manara'), const Offset(500, 0));
    await t.pumpAndSettle();
  });
}
