import 'package:atlas_mobile/app/app_lock.dart';
import 'package:atlas_mobile/app/notes.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/core/text/search_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_assessment.dart';
import 'fake_biometrics.dart';
import 'fake_catalog.dart';
import 'fake_learning.dart';
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

  group('notes and saved lessons', () {
    Future<ProviderContainer> openLesson(WidgetTester t) => pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/lesson/l2',
      size: const Size(393, 1400),
    );

    testWidgets('a note is written, shown in the lesson and listed', (t) async {
      final container = await openLesson(t);
      await t.tap(find.byTooltip('إضافة ملاحظة'));
      await t.pumpAndSettle();
      await t.enterText(
        find.byType(TextField).last,
        'النهاية من اليمين ≠ من اليسار',
      );
      await t.tap(find.text('حفظ الملاحظة'));
      await t.pumpAndSettle();
      expect(find.text('ملاحظتك'), findsOneWidget);
      expect(find.text('النهاية من اليمين ≠ من اليسار'), findsOneWidget);
      final n = container.read(notesProvider).single;
      expect(n.lessonTitle, 'النهايات من جهة واحدة');
      expect(n.courseTitle, 'التفاضل والتكامل');
      // Kept for this account in this academy.
      expect(
        container.read(sharedPreferencesProvider).getKeys(),
        contains(startsWith('notes.')),
      );
    });

    testWidgets('a lesson is saved from its top bar', (t) async {
      final container = await openLesson(t);
      await t.tap(find.byTooltip('حفظ الدرس'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byTooltip('إزالة من المحفوظات'), findsOneWidget);
      expect(container.read(notesProvider).single.saved, isTrue);
    });

    testWidgets('My notes says what to do while empty', (t) async {
      await pumpScreen(t, session: AsSignedIn.new, path: '/account/notes');
      expect(find.text('لا شيء هنا بعد'), findsOneWidget);
    });

    testWidgets('My notes lists what was kept and opens the lesson', (t) async {
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/account/notes',
      );
      await container
          .read(notesProvider.notifier)
          .put(
            LessonNote(
              courseId: FakeLearningRepository.courseId,
              lessonId: 'l2',
              courseTitle: 'التفاضل والتكامل',
              lessonTitle: 'النهايات من جهة واحدة',
              note: 'راجع المثال الثالث',
              saved: true,
              updatedAt: DateTime(2026, 10, 24),
            ),
          );
      await t.pump();
      expect(find.text('راجع المثال الثالث'), findsOneWidget);
      await t.tap(find.text('النهايات من جهة واحدة'));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('ملاحظتك'), findsOneWidget);
    });

    test('an emptied note that is not saved is dropped', () {
      final n = LessonNote(
        courseId: 'c',
        lessonId: 'l',
        courseTitle: 'C',
        lessonTitle: 'L',
        note: ' ',
        updatedAt: DateTime(2026),
      );
      expect(n.isEmpty, isTrue);
      expect(n.copyWith(saved: true).isEmpty, isFalse);
    });
  });

  group('due dates in the calendar', () {
    testWidgets('an assignment still to do: its due date goes in', (t) async {
      final added = <({String title, String description, DateTime dueAt})>[];
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/assignment/a1',
        size: const Size(393, 1400),
        assessments: _NotSubmitted(),
        calendar: (e) async {
          added.add(e);
          return true;
        },
      );
      await t.tap(find.text('إضافة إلى التقويم'));
      await t.pump();
      expect(added.single.title, 'موعد التسليم: واجب: تمارين النهايات');
      expect(added.single.description, 'الواجب');
      expect(
        added.single.dueAt.isAtSameMomentAs(
          testNow.add(const Duration(days: 3)),
        ),
        isTrue,
      );
    });

    testWidgets('says so when the calendar cannot open', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/assignment/a1',
        size: const Size(393, 1400),
        assessments: _NotSubmitted(),
        calendar: (_) async => false,
      );
      await t.tap(find.text('إضافة إلى التقويم'));
      await t.pump();
      expect(find.text('تعذّر فتح التقويم.'), findsOneWidget);
    });

    testWidgets('not offered once the work is submitted', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/assignment/a1',
        size: const Size(393, 1400),
      );
      expect(find.text('إضافة إلى التقويم'), findsNothing);
    });
  });

  group('app lock', () {
    testWidgets('hidden where the phone has no lock', (t) async {
      await pumpScreen(t, session: AsSignedIn.new, path: '/account/security');
      expect(find.text('قفل التطبيق بالبصمة أو الوجه'), findsNothing);
    });

    testWidgets('turned on only after the phone confirms', (t) async {
      final bio = FakeBiometrics(supported: true, passes: false);
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/account/security',
        biometrics: bio,
      );
      await t.tap(find.text('قفل التطبيق بالبصمة أو الوجه'));
      await t.pump();
      expect(bio.asked, 1);
      expect(container.read(appLockProvider).enabled, isFalse);

      bio.passes = true;
      await t.tap(find.text('قفل التطبيق بالبصمة أو الوجه'));
      await t.pump();
      expect(container.read(appLockProvider).enabled, isTrue);
      // Turning it on is not a lock in itself.
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
    });

    testWidgets('on: the app opens locked and asks at once', (t) async {
      final bio = FakeBiometrics(supported: true, passes: false);
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/home',
        biometrics: bio,
        prefs: {'security.appLock': true},
      );
      expect(find.byKey(const ValueKey('app-lock')), findsOneWidget);
      expect(bio.asked, 1);

      bio.passes = true;
      await t.tap(find.text('فتح القفل'));
      await t.pump();
      await t.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
    });
  });

  group('search in My courses', () {
    test('Arabic is matched the way people type it', () {
      expect(searchMatches('النهايات من جهة واحدة', 'نهايات واحده'), isTrue);
      expect(searchMatches('إحصاء', 'احصاء'), isTrue);
      expect(searchMatches('مُقَدِّمَة', 'مقدمه'), isTrue);
      expect(searchMatches('Organic Chemistry', 'chem org'), isTrue);
      expect(searchMatches('الفيزياء', 'كيمياء'), isFalse);
    });

    testWidgets('finds courses and lessons; a lesson opens', (t) async {
      await pumpScreen(t, session: AsSignedIn.new, path: '/courses');
      await t.enterText(find.byType(TextField).first, 'النهايات');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('الدروس'), findsOneWidget);
      // Every course has the same sample outline: one hit per course.
      expect(find.text('النهايات من جهة واحدة'), findsWidgets);
      await t.tap(find.text('مقدمة عن النهايات').first);
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      // The lesson screen (its files section).
      expect(find.text('ملفات الدرس'), findsOneWidget);
    });

    testWidgets('a course by its teacher; nothing found says so', (t) async {
      await pumpScreen(t, session: AsSignedIn.new, path: '/courses');
      await t.enterText(find.byType(TextField).first, 'منى');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('الكورسات'), findsOneWidget);
      expect(find.text('الفيزياء: الكهربية'), findsOneWidget);

      await t.enterText(find.byType(TextField).first, 'تاريخ');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('لا توجد نتائج لـ «تاريخ».'), findsOneWidget);

      await t.tap(find.byTooltip('مسح البحث'));
      await t.pump();
      expect(find.text('الكل'), findsOneWidget);
    });
  });
}

/// An assignment not handed in yet.
class _NotSubmitted extends FakeAssessmentRepository {
  @override
  Future<AssignmentSubmission?> submission(String courseId, String id) async =>
      null;
}
