import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/reminders.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_reminders.dart';
import 'screen_harness.dart';

/// Batch 2 of the app-only additions.
void main() {
  setUpAll(loadGoldenFonts);

  group('reminders', () {
    test('only work still to do, due later, nearest first', () {
      LearnerTask t(String id, String state, Duration? due) =>
          LearnerTask.fromJson({
            'id': id,
            'type': 'assignment',
            'title': id,
            'courseId': 'c',
            'courseTitle': 'C',
            'state': state,
            'dueAt': due == null ? null : testNow.add(due).toIso8601String(),
          });
      final due = RemindersController.dueSoon([
        t('later', 'not_started', const Duration(days: 5)),
        t('past', 'overdue', const Duration(days: -1)),
        t('soon', 'draft', const Duration(hours: 3)),
        t('done', 'submitted', const Duration(days: 1)),
        t('none', 'not_started', null),
      ], testNow);
      expect(due.map((d) => d.id), ['soon', 'later']);
    });

    Future<FakeReminders> openSettings(
      WidgetTester t, {
      bool granted = true,
    }) async {
      final fake = FakeReminders(granted: granted);
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/account/notifications',
        size: const Size(393, 1200),
        reminders: fake,
      );
      return fake;
    }

    testWidgets('due-date reminders: a day and an hour before each', (t) async {
      final fake = await openSettings(t);
      await t.tap(find.text('تذكير بمواعيد التسليم'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(fake.asked, 1);
      // a1 (due in 3 days) and a2 (6 days): both reminders each. The
      // overdue one and the ones without a date get none.
      expect(fake.scheduled.map((s) => s.path), [
        '/course/c-calc/assignment/a1',
        '/course/c-calc/assignment/a1',
        '/course/c-calc/assignment/a2',
        '/course/c-calc/assignment/a2',
      ]);
      expect(fake.scheduled.first.title, 'موعد التسليم غدًا: واجب الاتصال');
      expect(
        fake.scheduled.first.when!.isAtSameMomentAs(
          testNow.add(const Duration(days: 2)),
        ),
        isTrue,
      );
      expect(fake.scheduled[1].title, startsWith('باقٍ ساعة'));
    });

    testWidgets('daily reminder at 8 pm, naming the course to continue', (
      t,
    ) async {
      final fake = await openSettings(t);
      await t.tap(find.text('تذكير يومي بالمذاكرة'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(fake.dailyAt, (hour: 20, minute: 0));
      expect(fake.scheduled.single.body, 'أكمل التفاضل والتكامل من حيث توقفت.');
      expect(fake.scheduled.single.path, '/course/c-calc');
      expect(find.text('الوقت'), findsOneWidget);
    });

    testWidgets('refused by the system: stays off and says where to fix it', (
      t,
    ) async {
      final fake = await openSettings(t, granted: false);
      await t.tap(find.text('تذكير يومي بالمذاكرة'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(fake.scheduled, isEmpty);
      expect(find.textContaining('الإشعارات مقفلة'), findsOneWidget);
      expect(find.text('الوقت'), findsNothing);
    });

    testWidgets('signing out clears them', (t) async {
      final fake = FakeReminders();
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/account/notifications',
        reminders: fake,
        prefs: {'reminders.deadlines': true},
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(fake.scheduled, isNotEmpty);
      await container.read(sessionProvider.notifier).signOut();
      await t.pump();
      expect(fake.scheduled, isEmpty);
    });
  });
}
