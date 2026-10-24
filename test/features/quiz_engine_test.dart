import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/features/quiz/quiz_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

QuizAnswer pick(String q, List<String> ids) =>
    QuizAnswer(questionId: q, selected: ids);
QuizAnswer typed(String q, String t) => QuizAnswer(questionId: q, text: t);

SaveAnswersResult saved(int rev, {bool applied = true, List<Map>? answers}) =>
    SaveAnswersResult.fromJson({
      'revision': rev,
      'applied': applied,
      'savedAt': '2026-10-24T10:00:00Z',
      'serverNow': '2026-10-24T10:00:00Z',
      'deadlineAt': null,
      'answers': ?answers,
    });

const questions = [
  QuizSessionQuestion(id: 'a', type: 'single_choice', prompt: 'A'),
  QuizSessionQuestion(id: 'b', type: 'multiple_choice', prompt: 'B'),
  QuizSessionQuestion(id: 'c', type: 'short_answer', prompt: 'C'),
];

void main() {
  group('answers', () {
    test('blank answers are not answered and not sent', () {
      final map = toAnswerMap([
        pick('a', ['x']),
        typed('c', '   '),
      ]);
      expect(answeredCount(questions, map), 1);
      expect(unansweredNumbers(questions, map), [2, 3]);
      expect(toAnswerList(questions, map).map((a) => a.questionId), ['a']);
    });

    test('selection order does not make answers different', () {
      expect(pick('b', ['1', '2']).sameAs(pick('b', ['2', '1'])), isTrue);
      expect(pick('b', ['1']).sameAs(pick('b', ['1', '2'])), isFalse);
    });

    test('rebase keeps what the learner changed, takes the rest', () {
      final baseline = [
        pick('a', ['x']),
        pick('b', ['1']),
      ];
      final local = [
        pick('a', ['y']),
        pick('b', ['1']),
      ]; // changed a
      final server = [
        pick('a', ['x']),
        pick('b', ['2']),
      ]; // changed b
      final merged = toAnswerMap(rebaseAnswers(server, local, baseline));
      expect(merged['a']!.selected, ['y']);
      expect(merged['b']!.selected, ['2']);
    });

    test('rebase keeps a cleared answer the learner cleared', () {
      final merged = rebaseAnswers(
        [
          pick('a', ['x']),
        ],
        const [],
        [
          pick('a', ['x']),
        ],
      );
      expect(merged, isEmpty);
    });
  });

  group('clock', () {
    test('countdown text', () {
      expect(formatCountdown(65), '1:05');
      expect(formatCountdown(3725), '1:02:05');
      expect(formatCountdown(-3), '0:00');
    });

    test('announcements fire once, even across a skipped stretch', () {
      expect(crossedAnnouncement(601, 600), 600);
      expect(crossedAnnouncement(600, 599), isNull);
      expect(crossedAnnouncement(320, 290), 300);
      expect(crossedAnnouncement(null, 10), isNull);
    });

    test('remaining time comes from the server clock, not the phone', () {
      // The phone's clock is irrelevant: 90 s between serverNow and deadline.
      final clock = AttemptClock(
        serverNow: '2020-01-01T10:00:00Z',
        deadlineAt: '2020-01-01T10:01:30Z',
      );
      expect(clock.remaining(), inInclusiveRange(89, 90));
      expect(
        AttemptClock(serverNow: null, deadlineAt: null).remaining(),
        isNull,
      );
    });
  });

  group('autosave', () {
    test('debounces, then sends one save with the next revision', () {
      fakeAsync((async) {
        final sent = <int>[];
        final save = QuizAutosave(
          save: (rev, answers) async {
            sent.add(rev);
            return saved(rev);
          },
          initialRevision: 3,
          confirmed: const [],
        );
        save.schedule([
          pick('a', ['x']),
        ]);
        save.schedule([
          pick('a', ['y']),
        ]);
        async.elapse(const Duration(milliseconds: 1400));
        expect(sent, isEmpty);
        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();
        expect(sent, [4]);
        expect(save.state.value, AutosaveState.saved);
        expect(save.nextRevision, 5);
      });
    });

    test('an edit during a save goes out right after, never in parallel', () {
      fakeAsync((async) {
        var inFlight = 0, maxInFlight = 0;
        final revisions = <int>[];
        late QuizAutosave save;
        save = QuizAutosave(
          save: (rev, answers) async {
            inFlight++;
            maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
            revisions.add(rev);
            await Future<void>.delayed(const Duration(seconds: 1));
            inFlight--;
            return saved(rev);
          },
          initialRevision: 0,
          confirmed: const [],
        );
        save.schedule([
          pick('a', ['x']),
        ]);
        async.elapse(const Duration(milliseconds: 1600)); // first in flight
        save.schedule([
          pick('a', ['y']),
        ]);
        unawaitedFlush(save);
        async.elapse(const Duration(seconds: 5));
        expect(maxInFlight, 1);
        expect(revisions, [1, 2]);
      });
    });

    test('a stale save is rebased onto the server copy and resent', () {
      fakeAsync((async) {
        final bodies = <List<QuizAnswer>>[];
        var calls = 0;
        final save = QuizAutosave(
          save: (rev, answers) async {
            bodies.add(answers);
            calls++;
            if (calls == 1) {
              return saved(
                5,
                applied: false,
                answers: [
                  {
                    'questionId': 'b',
                    'selectedOptionIds': ['2'],
                  },
                ],
              );
            }
            return saved(rev);
          },
          initialRevision: 0,
          confirmed: const [],
        );
        save.schedule([
          pick('a', ['x']),
        ]);
        async.elapse(const Duration(seconds: 3));
        expect(calls, 2);
        final second = toAnswerMap(bodies[1]);
        expect(second['a']!.selected, ['x']); // learner's edit kept
        expect(second['b']!.selected, ['2']); // server's newer copy taken
        expect(save.state.value, AutosaveState.saved);
      });
    });

    test('a failed save is retried and keeps the answers', () {
      fakeAsync((async) {
        var calls = 0;
        final save = QuizAutosave(
          save: (rev, answers) async {
            calls++;
            if (calls == 1) {
              throw const AtlasApiException(
                kind: 'network',
                messageKey: 'errors.network',
              );
            }
            return saved(rev);
          },
          initialRevision: 0,
          confirmed: const [],
        );
        save.schedule([
          pick('a', ['x']),
        ]);
        async.elapse(const Duration(milliseconds: 1600));
        expect(save.state.value, AutosaveState.offline);
        async.elapse(const Duration(seconds: 3));
        expect(calls, 2);
        expect(save.state.value, AutosaveState.saved);
      });
    });

    test('an attempt over on the server stops the queue', () {
      fakeAsync((async) {
        var terminal = false, calls = 0;
        final save = QuizAutosave(
          save: (rev, answers) async {
            calls++;
            throw const AtlasApiException(
              kind: 'conflict',
              messageKey: 'errors.quiz.attemptExpired',
            );
          },
          initialRevision: 0,
          confirmed: const [],
          onTerminal: () => terminal = true,
        );
        save.schedule([
          pick('a', ['x']),
        ]);
        async.elapse(const Duration(seconds: 30));
        expect(terminal, isTrue);
        expect(calls, 1);
        save.schedule([
          pick('a', ['y']),
        ]);
        async.elapse(const Duration(seconds: 5));
        expect(calls, 1);
      });
    });
  });

  group('integrity', () {
    test('records full screen at start, leaving the app, and acts on warn', () {
      fakeAsync((async) {
        final batches = <List<String>>[];
        (int, int)? warned;
        final integrity = QuizIntegrity(
          record: (events) async {
            batches.add([for (final e in events) e['type']! as String]);
            return EventsResult.fromJson({
              'violationCount': 1,
              'maxViolations': 3,
              'action': 'warn',
            });
          },
          mode: 'warn',
          onWarn: (v, m) => warned = (v, m),
        )..start();
        integrity.push('visibility_hidden'); // sent at once
        async.flushMicrotasks();
        expect(batches.single, ['fullscreen_enter', 'visibility_hidden']);
        expect(warned, (1, 3));
        integrity.dispose();
      });
    });

    test('mode off records nothing', () {
      fakeAsync((async) {
        var calls = 0;
        final integrity = QuizIntegrity(
          record: (events) async {
            calls++;
            return EventsResult.fromJson(const {});
          },
          mode: 'off',
        )..start();
        integrity.push('visibility_hidden');
        async.elapse(const Duration(minutes: 3));
        expect(calls, 0);
      });
    });
  });
}

void unawaitedFlush(QuizAutosave s) {
  s.flush();
}
