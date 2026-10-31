import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_catalog.dart';
import 'screen_harness.dart';

/// Batch 3 of the app-only additions.
void main() {
  setUpAll(loadGoldenFonts);

  group('recommended courses', () {
    testWidgets('related free courses close the preview and open', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/catalog/free-algebra',
        size: const Size(393, 3000),
        catalog: RatedCatalog(),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('كورسات قد تعجبك'), findsOneWidget);
      // The course itself is never suggested to itself.
      expect(find.text('أساسيات الجبر'), findsOneWidget);
      await t.tap(find.text('مدخل إلى الفيزياء'));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('مدخل إلى الفيزياء'), findsWidgets);
      expect(find.text('أ. منى'), findsOneWidget);
    });

    testWidgets('no section when there is nothing to suggest', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/catalog/free-algebra',
        size: const Size(393, 3000),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('كورسات قد تعجبك'), findsNothing);
    });
  });
}
