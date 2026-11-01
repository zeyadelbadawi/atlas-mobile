import 'package:atlas_mobile/app/notes.dart';
import 'package:atlas_mobile/app/push.dart';
import 'package:atlas_mobile/app/streak.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart' show loadGoldenFonts, testNow;
import 'fake_learning.dart';
import 'fake_reminders.dart';
import 'screen_harness.dart';

/// A server that is not reachable (or has no notes yet).
class _Offline extends FakeLearningRepository {
  bool online = false;

  @override
  Future<List<ServerNote>> notes() async {
    if (!online) {
      throw const AtlasApiException(
        kind: 'network',
        messageKey: 'errors.network',
      );
    }
    return super.notes();
  }

  @override
  Future<ServerNote> putNote({
    required String courseId,
    required String lessonId,
    required String note,
    required bool saved,
    required DateTime editedAt,
  }) {
    if (!online) {
      throw const AtlasApiException(
        kind: 'network',
        messageKey: 'errors.network',
      );
    }
    return super.putNote(
      courseId: courseId,
      lessonId: lessonId,
      note: note,
      saved: saved,
      editedAt: editedAt,
    );
  }
}

/// Push on, and the server sends the day-before due-date push.
class _ServerDue extends PushController {
  @override
  PushStatus build() => PushStatus.granted;

  @override
  bool get serverDueReminders => true;
}

ServerNote _server(
  String lesson,
  String note,
  DateTime at, {
  bool saved = false,
}) => ServerNote.fromJson({
  'courseId': 'c1',
  'lessonId': lesson,
  'courseTitle': 'التفاضل',
  'lessonTitle': 'النهايات',
  'note': note,
  'saved': saved,
  'editedAt': at.toUtc().toIso8601String(),
});

LessonNote _local(String lesson, String note, DateTime at) => LessonNote(
  courseId: 'c1',
  lessonId: lesson,
  courseTitle: 'التفاضل',
  lessonTitle: 'النهايات',
  note: note,
  updatedAt: at,
);

void main() {
  setUpAll(loadGoldenFonts);
  group('notes sync', () {
    testWidgets('an edit here is sent to the server', (t) async {
      final learning = FakeLearningRepository();
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        learning: learning,
      );
      await c.read(notesProvider.notifier).put(_local('l1', 'راجع', testNow));
      await t.pump();
      expect(learning.serverNotes['l1']?.note, 'راجع');
    });

    testWidgets('a newer edit from another phone wins; an older one does not', (
      t,
    ) async {
      final learning = FakeLearningRepository();
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        learning: learning,
      );
      final notes = c.read(notesProvider.notifier);
      await notes.put(_local('l1', 'هنا', testNow));
      await notes.put(_local('l2', 'هنا أحدث', testNow));
      learning.serverNotes['l1'] = _server(
        'l1',
        'من موبايل تاني',
        testNow.add(const Duration(minutes: 5)),
      );
      learning.serverNotes['l2'] = _server(
        'l2',
        'أقدم',
        testNow.subtract(const Duration(minutes: 5)),
      );
      await notes.sync();
      expect(notes.of('l1')?.note, 'من موبايل تاني');
      expect(notes.of('l2')?.note, 'هنا أحدث');
    });

    testWidgets('a note deleted on another phone goes here too', (t) async {
      final learning = FakeLearningRepository();
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        learning: learning,
      );
      final notes = c.read(notesProvider.notifier);
      await notes.put(_local('l1', 'هنا', testNow));
      learning.serverNotes['l1'] = _server(
        'l1',
        '',
        testNow.add(const Duration(minutes: 1)),
      );
      await notes.sync();
      expect(notes.of('l1'), isNull);
    });

    testWidgets('edits made offline are kept and sent later', (t) async {
      final learning = _Offline();
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        learning: learning,
      );
      final notes = c.read(notesProvider.notifier);
      await notes.put(_local('l1', 'بدون نت', testNow));
      await t.pump();
      expect(notes.of('l1')?.note, 'بدون نت');
      expect(learning.serverNotes, isEmpty);
      learning.online = true;
      await notes.sync();
      expect(learning.serverNotes['l1']?.note, 'بدون نت');
    });

    testWidgets('notes kept before sync existed are uploaded once', (t) async {
      final learning = FakeLearningRepository();
      final c = await pumpScreen(
        t,
        session: AsSignedIn.new,
        learning: learning,
        prefs: {
          'notes.${ziadd.id}.u1': '[{"courseId":"c1","lessonId":"l9","note":"قديمة","saved":true,"updatedAt":"2026-10-01T10:00:00.000"}]',
        },
      );
      await c.read(notesProvider.notifier).sync();
      expect(learning.serverNotes['l9']?.note, 'قديمة');
      expect(learning.serverNotes['l9']?.saved, isTrue);
    });
  });

  testWidgets('study days from the server join the phone’s streak', (t) async {
    final learning = FakeLearningRepository()
      ..serverDays.addAll(['2026-10-24', '2026-10-23', '2026-10-22', 'bad']);
    final c = await pumpScreen(t, session: AsSignedIn.new, learning: learning);
    await t.pump(const Duration(milliseconds: 100));
    expect(
      c.read(studyDaysProvider),
      containsAll(['2026-10-22', '2026-10-24']),
    );
    expect(c.read(studyDaysProvider), isNot(contains('bad')));
    expect(c.read(streakProvider), 3);
  });

  group('due-date reminders', () {
    Future<List<String>> dueTitles(
      WidgetTester t, {
      required bool server,
    }) async {
      final fake = FakeReminders();
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/account/notifications',
        reminders: fake,
        prefs: {'reminders.deadlines': true},
        push: server ? _ServerDue.new : null,
      );
      await t.pump(const Duration(milliseconds: 300));
      return [
        for (final s in fake.scheduled)
          if (s.when != null) s.title,
      ];
    }

    testWidgets('without the server, the phone sends both', (t) async {
      final titles = await dueTitles(t, server: false);
      expect(titles, contains(startsWith('موعد التسليم غدًا')));
      expect(titles, contains(startsWith('باقٍ ساعة')));
    });

    testWidgets('with the server, the phone sends only the hour-before one', (
      t,
    ) async {
      final titles = await dueTitles(t, server: true);
      expect(titles, isNotEmpty);
      expect(titles, everyElement(startsWith('باقٍ ساعة')));
    });
  });
}
