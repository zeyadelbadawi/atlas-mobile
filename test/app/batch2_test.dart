import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/lesson_outbox.dart';
import 'package:atlas_mobile/app/reminders.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_learning.dart';
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

  group('lesson done without a connection', () {
    Future<ProviderContainer> openLesson(WidgetTester t, _Flaky learning) =>
        pumpScreen(
          t,
          session: AsSignedIn.new,
          path: '/course/${FakeLearningRepository.courseId}/lesson/l2',
          size: const Size(393, 1400),
          learning: learning,
        );

    Future<void> press(WidgetTester t, String label) async {
      await t.ensureVisible(find.text(label));
      await t.tap(find.text(label));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
    }

    testWidgets('is kept on the phone and sent when the connection returns', (
      t,
    ) async {
      final learning = _Flaky();
      final container = await openLesson(t, learning);
      await press(t, 'أكملت الدرس');
      expect(
        find.text('حُفظ على الهاتف، وسيُرسل عند عودة الاتصال.'),
        findsOneWidget,
      );
      expect(find.text('تم، وفي انتظار الاتصال لإرساله.'), findsOneWidget);
      final queued = container.read(lessonOutboxProvider);
      expect(queued.single.lessonId, 'l2');
      expect(
        container.read(sharedPreferencesProvider).getKeys(),
        contains(startsWith('outbox.lessons.')),
      );

      learning.online = true;
      await container.read(lessonOutboxProvider.notifier).flush();
      await t.pump();
      expect(container.read(lessonOutboxProvider), isEmpty);
      // Sent with the stamp of when it was pressed, not when it left.
      expect(learning.sent.single, (
        'complete',
        'l2',
        queued.single.opId,
        queued.single.at,
      ));
    });

    testWidgets('a later choice replaces the waiting one', (t) async {
      final learning = _Flaky();
      final container = await openLesson(t, learning);
      await press(t, 'أكملت الدرس');
      await press(t, 'إلغاء الإكمال');
      final q = container.read(lessonOutboxProvider);
      expect(q.single.complete, isFalse);
      expect(find.text('أكملت الدرس'), findsOneWidget);

      // Back online: the retry sends only the newest choice.
      learning.online = true;
      await t.pump(const Duration(seconds: 31));
      await t.pump();
      expect(container.read(lessonOutboxProvider), isEmpty);
      expect(learning.sent.map((s) => s.$1), ['undo']);
    });

    testWidgets('a refusal that is not the connection is shown, not kept', (
      t,
    ) async {
      final learning = _Flaky()..refuse = true;
      final container = await openLesson(t, learning);
      await press(t, 'أكملت الدرس');
      expect(container.read(lessonOutboxProvider), isEmpty);
      expect(find.text('أكملت الدرس'), findsOneWidget);
    });
  });

  group('rating an enrolled course', () {
    Future<FakeLearningRepository> openCourse(WidgetTester t) async {
      final learning = FakeLearningRepository();
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/${FakeLearningRepository.courseId}',
        size: const Size(393, 1800),
        learning: learning,
      );
      return learning;
    }

    testWidgets('four stars and a comment, then waiting for approval', (
      t,
    ) async {
      final learning = await openCourse(t);
      expect(find.text('قيّم هذا الكورس'), findsOneWidget);
      await t.ensureVisible(find.byTooltip('٤ من ٥').first);
      await t.tap(find.byTooltip('٤ من ٥').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, 'شرح ممتاز');
      await t.tap(find.text('إرسال التقييم'));
      await t.pumpAndSettle();
      expect(learning.review?.rating, 4);
      expect(learning.review?.body, 'شرح ممتاز');
      expect(find.text('بانتظار موافقة الأكاديمية'), findsOneWidget);
      expect(find.text('تقييمك'), findsOneWidget);
    });

    testWidgets('can be deleted after a confirm', (t) async {
      final learning = FakeLearningRepository();
      await learning.saveReview('c-calc', rating: 5);
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/${FakeLearningRepository.courseId}',
        size: const Size(393, 1800),
        learning: learning,
      );
      await t.ensureVisible(find.text('حذف'));
      await t.tap(find.text('حذف'));
      await t.pumpAndSettle();
      await t.tap(find.text('حذف').last);
      await t.pumpAndSettle();
      expect(learning.review, isNull);
      expect(find.text('قيّم هذا الكورس'), findsOneWidget);
    });
  });
}

/// A connection that is down until [online]; or a server that refuses.
class _Flaky extends FakeLearningRepository {
  bool online = false;
  bool refuse = false;
  final sent = <(String, String, String?, int?)>[];

  void _check() {
    if (refuse) {
      throw const AtlasApiException(
        kind: 'forbidden',
        messageKey: 'errors.forbidden',
        status: 403,
      );
    }
    if (!online) {
      throw const AtlasApiException(
        kind: 'network',
        messageKey: 'errors.network.offline',
        retryable: true,
      );
    }
  }

  @override
  Future<double> completeLesson(
    String courseId,
    String lessonId, {
    String? opId,
    int? clientOpAt,
  }) async {
    _check();
    sent.add(('complete', lessonId, opId, clientOpAt));
    return 50;
  }

  @override
  Future<void> undoCompleteLesson(
    String courseId,
    String lessonId, {
    String? opId,
    int? clientOpAt,
  }) async {
    _check();
    sent.add(('undo', lessonId, opId, clientOpAt));
  }
}
