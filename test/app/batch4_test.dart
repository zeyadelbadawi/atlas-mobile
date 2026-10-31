import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_home_widgets.dart';
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
}
