import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/academy/academy_directory.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'screen_harness.dart';

/// Records which host the picker asked for, and says "not found" so the
/// test stays on the picker.
class _Directory extends AcademyDirectory {
  _Directory() : super(platformHost: 'atlass.dpdns.org');
  final asked = <String>[];

  @override
  Future<Academy> resolve(String host) async {
    asked.add(host);
    throw const AtlasApiException(
      kind: 'not_found',
      messageKey: 'errors.academy.notFound',
      status: 404,
    );
  }
}

void main() {
  setUpAll(loadGoldenFonts);

  group('hostFor', () {
    final dir = AcademyDirectory(platformHost: 'atlass.dpdns.org');
    test('a short name goes on Atlas\'s domain', () {
      expect(dir.hostFor('ziadd'), 'ziadd.atlass.dpdns.org');
      expect(dir.hostFor('  Demoo '), 'demoo.atlass.dpdns.org');
    });
    test('a full address or link is used as typed', () {
      expect(dir.hostFor('ziadd.atlass.dpdns.org'), 'ziadd.atlass.dpdns.org');
      expect(
        dir.hostFor('https://ziadd.atlass.dpdns.org/courses/x'),
        'ziadd.atlass.dpdns.org',
      );
      expect(dir.hostFor('learn.my-academy.com'), 'learn.my-academy.com');
    });
    test('nonsense is refused', () {
      expect(dir.hostFor(''), isNull);
      expect(dir.hostFor('-bad-'), isNull);
    });
  });

  testWidgets(
    'the learner types only the name; the domain is shown, not typed',
    (t) async {
      final dir = _Directory();
      await pumpScreen(t, session: AsNoAcademy.new, directory: dir);
      final field = find.byType(TextField);

      // The shared domain sits after the field from the start.
      expect(find.text('.atlass.dpdns.org'), findsOneWidget);

      await t.enterText(field, 'ziadd');
      await t.pump();
      expect(find.text('.atlass.dpdns.org'), findsOneWidget);
      await t.testTextInput.receiveAction(TextInputAction.go);
      await t.pump();
      expect(dir.asked.last, 'ziadd.atlass.dpdns.org');

      // An academy on its own domain: the suffix steps aside.
      await t.enterText(field, 'learn.my-academy.com');
      await t.pump();
      expect(find.text('.atlass.dpdns.org'), findsNothing);
      await t.testTextInput.receiveAction(TextInputAction.go);
      await t.pump();
      expect(dir.asked.last, 'learn.my-academy.com');

      // "Not this domain": back to the name, then the explicit switch.
      await t.tap(find.text('أكاديميتك على أطلس؟ اكتب اسمها فقط'));
      await t.pump();
      expect(find.text('.atlass.dpdns.org'), findsOneWidget);
      expect(find.text('learn.my-academy.com'), findsNothing);
      await t.tap(find.text('لأكاديميتك دومين خاص؟'));
      await t.pump();
      expect(find.text('.atlass.dpdns.org'), findsNothing);
      expect(find.text('عنوان موقع الأكاديمية'), findsOneWidget);

      // Spaces can't be typed into a name.
      await t.enterText(field, 'my academy');
      await t.pump();
      expect(find.text('myacademy'), findsOneWidget);
    },
  );
}
