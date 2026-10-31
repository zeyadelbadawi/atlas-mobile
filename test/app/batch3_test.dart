import 'package:atlas_mobile/app/notes.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
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
}
