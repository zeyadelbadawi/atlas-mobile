import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/router.dart';
import 'package:atlas_mobile/app/streak.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_home_widgets.dart';
import 'fake_learning.dart';
import 'fake_shortcuts.dart';
import 'screen_harness.dart';

/// Batch 4 of the app-only additions.
void main() {
  setUpAll(loadGoldenFonts);

  group('app icon shortcuts', () {
    testWidgets('signed in: continue, tasks, notes, notifications', (t) async {
      final s = FakeShortcuts();
      await pumpScreen(t, session: AsSignedIn.new, shortcuts: s);
      await t.pump(const Duration(milliseconds: 300));
      expect(s.items.map((i) => i.path), [
        '/course/c-calc',
        '/tasks',
        '/account/notes',
        '/notifications',
      ]);
      expect(s.items.first.title, 'متابعة التعلّم');
    });

    testWidgets('a shortcut opens its screen', (t) async {
      final s = FakeShortcuts();
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        shortcuts: s,
      );
      await t.pump(const Duration(milliseconds: 300));
      s.open!('/tasks');
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      final router = container.read(routerProvider);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/tasks');

      // A course: on top of Home, so Back has somewhere to go.
      s.open!('/course/c-calc');
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('استكمل'), findsOneWidget);
      expect(router.canPop(), isTrue);
    });

    testWidgets('signed out: none', (t) async {
      final s = FakeShortcuts();
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        shortcuts: s,
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(s.items, isNotEmpty);
      await container.read(sessionProvider.notifier).signOut();
      await t.pump();
      await t.pump();
      expect(s.items, isEmpty);
    });
  });

  group('home-screen widget', () {
    testWidgets('signed in: the course, next lesson, progress, due date', (
      t,
    ) async {
      final w = FakeHomeWidgets();
      await pumpScreen(t, session: AsSignedIn.new, homeWidgets: w);
      await t.pump(const Duration(milliseconds: 300));
      expect(w.data['signedIn'], isTrue);
      expect(w.data['rtl'], isTrue);
      expect(w.data['label'], 'متابعة التعلّم');
      expect(w.data['course'], 'التفاضل والتكامل');
      expect(w.data['lesson'], 'التالي: النهايات من جهة واحدة');
      expect(w.data['percent'], 29);
      expect(w.data['percentText'], 'تم ٢٩٪');
      expect(w.data['due'], startsWith('التسليم '));
      expect(w.data['due'], endsWith(': واجب الاتصال'));
      expect(w.data['path'], '/course/c-calc');
    });

    testWidgets('signed out: asks to sign in', (t) async {
      final w = FakeHomeWidgets();
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        homeWidgets: w,
      );
      await t.pump(const Duration(milliseconds: 300));
      await container.read(sessionProvider.notifier).signOut();
      await t.pump();
      await t.pump();
      expect(w.data['signedIn'], isFalse);
      expect(w.data['empty'], 'سجّل الدخول إلى أطلس لترى كورساتك هنا.');
    });

    testWidgets('a tap on the widget opens the course', (t) async {
      final w = FakeHomeWidgets();
      await pumpScreen(t, session: AsSignedIn.new, homeWidgets: w);
      await t.pump(const Duration(milliseconds: 300));
      w.tapped.add('/course/c-calc');
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('استكمل'), findsOneWidget);
    });
  });

  group('study streak', () {
    String d(int daysAgo) =>
        StudyDays.day(testNow.subtract(Duration(days: daysAgo)));

    test('counts days in a row; today not yet studied does not break it', () {
      expect(streakOf({}, testNow), 0);
      expect(streakOf({d(0), d(1), d(2)}, testNow), 3);
      expect(streakOf({d(1), d(2)}, testNow), 2); // not yet today
      expect(streakOf({d(0), d(2), d(3)}, testNow), 1); // a gap
      expect(streakOf({d(2), d(3)}, testNow), 0); // missed yesterday
    });

    testWidgets('Home shows the streak and the week', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/home',
        size: const Size(393, 1400),
        prefs: {
          'study.days.${ziadd.id}.u1': [d(0), d(1), d(2)],
        },
      );
      expect(find.text('٣ أيام متتالية'), findsOneWidget);
      expect(find.text('احتُسب يومك. واصل غدًا.'), findsOneWidget);
    });

    testWidgets('finishing a lesson counts today', (t) async {
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/lesson/l2',
        size: const Size(393, 1400),
      );
      expect(container.read(streakProvider), 0);
      await t.ensureVisible(find.text('أكملت الدرس'));
      await t.tap(find.text('أكملت الدرس'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(container.read(streakProvider), 1);
    });
  });

  group('text lessons without a connection', () {
    testWidgets('a lesson read once opens again offline, saying so', (t) async {
      final learning = _Connection();
      final container = await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/lesson/l2',
        size: const Size(393, 1400),
        learning: learning,
      );
      expect(find.text('ملفات الدرس'), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-offline-copy')), findsNothing);

      // Offline now; open it again.
      learning.online = false;
      final router = container.read(routerProvider);
      router.pop();
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      router.push('/course/c-calc/lesson/l2');
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('lesson-offline-copy')), findsOneWidget);
      expect(
        find.textContaining('النهاية من اليمين', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('never read before: the usual offline message', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/c-calc/lesson/l2',
        learning: _Connection()..online = false,
      );
      expect(find.byKey(const ValueKey('lesson-offline-copy')), findsNothing);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}

/// The lesson content needs the network; [online] says whether there is
/// one.
class _Connection extends FakeLearningRepository {
  bool online = true;

  @override
  Future<LessonGrant> grant(String courseId, String lessonId) async {
    if (!online) {
      throw const AtlasApiException(
        kind: 'network',
        messageKey: 'errors.network.offline',
        retryable: true,
      );
    }
    return super.grant(courseId, lessonId);
  }
}
