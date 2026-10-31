import 'package:atlas_mobile/app/router.dart';
import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

/// Small frictions found in the UX review, kept fixed.
void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('the email typed at sign-in carries over to "create account"', (
    t,
  ) async {
    final container = await pumpScreen(t, session: AsSignedOut.new);
    await t.enterText(find.byType(TextField).first, 'sara@example.com');
    container
        .read(routerProvider)
        .push('/academy/register', extra: 'sara@example.com');
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('sara@example.com'), findsWidgets);
  });

  testWidgets('catalog search has a clear button once something is typed', (
    t,
  ) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/catalog');
    expect(find.byTooltip('مسح البحث'), findsNothing);
    await t.enterText(find.byType(TextField).first, 'جبر');
    await t.pump();
    expect(find.byTooltip('مسح البحث'), findsOneWidget);
    await t.tap(find.byTooltip('مسح البحث'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('جبر'), findsNothing);
    expect(find.byTooltip('مسح البحث'), findsNothing);
  });

  testWidgets('profile: Save waits for a change', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/account/profile');
    AtlasButton nameSave() => t.widget<AtlasButton>(
      find.ancestor(
        of: find.text('حفظ').first,
        matching: find.byType(AtlasButton),
      ),
    );

    expect(nameSave().onPressed, isNull);
    await t.enterText(find.byType(TextField).first, 'زياد محمد');
    await t.pump();
    expect(nameSave().onPressed, isNotNull);
    // Back to what is saved: nothing to save again.
    await t.enterText(find.byType(TextField).first, 'زياد البدوي');
    await t.pump();
    expect(nameSave().onPressed, isNull);
  });

  testWidgets('sign-in starts with the email last used at this academy', (
    t,
  ) async {
    await pumpScreen(
      t,
      session: AsSignedOut.new,
      prefs: {'signin.lastEmail.ziadd.atlass.dpdns.org': 'zeyad@example.com'},
    );
    expect(find.text('zeyad@example.com'), findsOneWidget);
  });

  testWidgets('a locked lesson says why when tapped', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}',
      size: const Size(393, 1600),
    );
    await t.tap(find.text('تعريف الاتصال'));
    await t.pump();
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('أكمل العنصر السابق أولًا'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('change password: an empty current password says what to do', (
    t,
  ) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/account/security');
    await t.tap(find.widgetWithText(AtlasButton, 'تغيير كلمة المرور'));
    await t.pump();
    expect(find.text('اكتب كلمة المرور الحالية.'), findsOneWidget);
  });
}
