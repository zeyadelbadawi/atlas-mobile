import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/streak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'screen_harness.dart';

String _d(int daysAgo) =>
    StudyDays.day(testNow.subtract(Duration(days: daysAgo)));

void main() {
  setUpAll(loadGoldenFonts);

  group('weekly goal', () {
    testWidgets('no goal: the card offers one; picking it is kept', (t) async {
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/home',
        size: const Size(393, 1400),
        prefs: {
          'study.days.${ziadd.id}.u1': [_d(0)],
        },
      );
      expect(find.text('حدّد هدفًا أسبوعيًا'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('goal-set')));
      await t.pumpAndSettle();
      expect(find.text('هدفك الأسبوعي'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('goal-3')));
      await t.pumpAndSettle();
      expect(c.read(weeklyGoalProvider), 3);
      expect(c.read(sharedPreferencesProvider).getInt(WeeklyGoal.key), 3);
      expect(find.text('هدفك: ١ من ٣ أيام في آخر ٧ أيام'), findsOneWidget);
    });

    testWidgets('the goal counts the last seven days, and says when reached', (
      t,
    ) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/home',
        size: const Size(393, 1400),
        prefs: {
          WeeklyGoal.key: 3,
          // Three of the last seven days; the eighth day back does not count.
          'study.days.${ziadd.id}.u1': [_d(0), _d(3), _d(6), _d(7)],
        },
      );
      expect(find.text('حققت هدفك في آخر ٧ أيام.'), findsOneWidget);
    });

    testWidgets('the goal can be turned off', (t) async {
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/home',
        size: const Size(393, 1400),
        prefs: {WeeklyGoal.key: 4},
      );
      expect(find.text('هدفك: ٠ من ٤ أيام في آخر ٧ أيام'), findsOneWidget);
      await t.tap(find.byTooltip('تغيير الهدف الأسبوعي'));
      await t.pumpAndSettle();
      await t.tap(find.text('بدون هدف'));
      await t.pumpAndSettle();
      expect(c.read(weeklyGoalProvider), isNull);
      expect(find.text('حدّد هدفًا أسبوعيًا'), findsOneWidget);
    });
  });
}
