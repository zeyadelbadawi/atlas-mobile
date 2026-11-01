import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/streak.dart';
import 'package:atlas_mobile/core/platform/calendar.dart';
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

  group('live classes (view only)', () {
    Future<void> open(WidgetTester t, String id, {AddToCalendar? calendar}) =>
        pumpScreen(
          t,
          session: AsSignedIn.new,
          path: '/course/c-calc/live/$id',
          calendar: calendar,
        );

    testWidgets('an upcoming class: date, countdown, calendar; no join yet', (
      t,
    ) async {
      DueEvent? added;
      await open(
        t,
        'ls-next',
        calendar: (e) async {
          added = e;
          return true;
        },
      );
      expect(find.text('مراجعة النهايات قبل الامتحان'), findsOneWidget);
      expect(find.text('مع أ. أحمد سمير'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-countdown')), findsOneWidget);
      // 2 days, 3 hours, 20 minutes.
      expect(find.text('٢'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
      expect(find.text('٢٠'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-join')), findsNothing);
      await t.tap(find.byKey(const ValueKey('live-calendar')));
      await t.pump();
      expect(
        added!.startsAt,
        testNow.add(const Duration(days: 2, hours: 3, minutes: 20)),
      );
      expect(
        added!.dueAt,
        testNow.add(const Duration(days: 2, hours: 4, minutes: 20)),
      );
    });

    testWidgets('a class on now offers to join on the website', (t) async {
      await open(t, 'ls-now');
      expect(find.text('مباشرة الآن'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-join')), findsOneWidget);
      expect(find.byKey(const ValueKey('live-countdown')), findsNothing);
    });

    testWidgets(
      'an ended class offers its recording; a cancelled one says so',
      (t) async {
        await open(t, 'ls-done');
        expect(find.text('انتهت هذه الحصة.'), findsOneWidget);
        expect(find.text('شاهد التسجيل على موقع الأكاديمية'), findsOneWidget);
      },
    );

    testWidgets('a cancelled class says so, with no join or countdown', (
      t,
    ) async {
      await open(t, 'ls-off');
      expect(find.text('أُلغيت هذه الحصة.'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-join')), findsNothing);
      expect(find.byKey(const ValueKey('live-countdown')), findsNothing);
    });
  });
}
