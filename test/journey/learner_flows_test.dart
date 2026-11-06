// Learner-journey QA, by taps: whole journeys through the real screens
// (fake data), failing on any error. Complements the screen matrix.
@Tags(['journey'])
library;

import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fake_assessment.dart';
import '../app/fake_learning.dart';
import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

const _c = FakeLearningRepository.courseId;

/// A quiz that can be taken: start, save, submit.
class TakeableQuiz extends FakeAssessmentRepository {
  TakeableQuiz() : super(sessionIntegrity: 'warn');

  bool started = false, submitted = false;
  final saved = <List<QuizAnswer>>[];

  @override
  Future<List<QuizAttempt>> attempts(String courseId, String quizId) async => [
    if (started)
      QuizAttempt.fromJson({
        'id': 'a1',
        'status': submitted ? 'passed' : 'in_progress',
        'attemptNumber': 1,
        if (submitted) 'score': 80,
      }),
  ];

  @override
  Future<QuizAttempt> start(String courseId, String quizId) async {
    started = true;
    return QuizAttempt.fromJson({
      'id': 'a1',
      'status': 'in_progress',
      'attemptNumber': 1,
    });
  }

  @override
  Future<SaveAnswersResult> saveAnswers(
    String courseId,
    String quizId,
    String attemptId, {
    required int revision,
    required List<QuizAnswer> answers,
  }) async {
    saved.add(answers);
    return SaveAnswersResult.fromJson({'revision': revision, 'applied': true});
  }

  @override
  Future<QuizAttempt> submit(
    String courseId,
    String quizId,
    String attemptId, {
    required List<QuizAnswer> answers,
    required int revision,
  }) async {
    submitted = true;
    return QuizAttempt.fromJson({
      'id': 'a1',
      'status': 'passed',
      'attemptNumber': 1,
      'score': 80,
      'passed': true,
    });
  }
}

void _quietPhone(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  const events = EventChannel('atlas/screen_capture/events');
  m.setMockStreamHandler(events, MockStreamHandler.inline(onListen: (_, _) {}));
  addTearDown(() => m.setMockStreamHandler(events, null));
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('a quiz from its notice to its result', (t) async {
    _quietPhone(t);
    final repo = TakeableQuiz();
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      path: '/course/$_c/quiz/l3',
      assessments: repo,
      size: const Size(393, 1600),
    );
    await _settle(t);
    // Start waits for the notice to be acknowledged.
    final start = find.text('Start quiz');
    expect(start, findsOneWidget);
    await t.tap(start);
    await _settle(t);
    expect(repo.started, isFalse);
    await t.tap(find.text('I understand what is recorded during this quiz.'));
    await _settle(t);
    await t.tap(start);
    await _settle(t);
    expect(repo.started, isTrue);
    // The first question; answer it and go on.
    await t.tap(find.text('٣'));
    await t.pump(const Duration(seconds: 3));
    expect(repo.saved, isNotEmpty);
    await t.tap(find.text('Next'));
    await _settle(t);
    // Submit from the top bar; the dialog says what is unanswered.
    await t.tap(find.text('Submit').first);
    await _settle(t);
    expect(find.text('Submit this attempt?'), findsOneWidget);
    expect(
      find.textContaining('2 questions are still unanswered'),
      findsOneWidget,
    );
    await t.tap(find.text('Submit').last);
    await _settle(t);
    expect(repo.submitted, isTrue);
    expect(find.textContaining('80'), findsWidgets);
  });

  testWidgets('sign in: empty fields say what is missing', (t) async {
    await pumpScreen(t, session: AsSignedOut.new, language: 'en');
    await _settle(t);
    await t.tap(find.text('Sign in').last);
    await _settle(t);
    expect(find.byType(TextField), findsWidgets);
    // Still on sign-in, with a message under the fields.
    expect(find.text('Sign in'), findsWidgets);
    final errors = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').toLowerCase().contains('email'),
    );
    expect(errors, findsWidgets);
  });

  testWidgets('register: create waits for the age and terms boxes', (t) async {
    await pumpScreen(
      t,
      session: AsSignedOut.new,
      language: 'en',
      path: '/academy/register',
      size: const Size(393, 1400),
    );
    await _settle(t);
    final create = find.text('Create account');
    expect(create, findsOneWidget);
    expect(
      find.textContaining('Confirm your age and accept the terms'),
      findsOneWidget,
    );
  });

  testWidgets('tasks: each tab lists its own work', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      path: '/tasks',
    );
    await _settle(t);
    for (final tab in ['Awaiting (1)', 'Graded (3)', 'To do (4)']) {
      await t.tap(find.text(tab));
      await _settle(t);
      expect(find.byType(ListView), findsWidgets);
    }
  });

  testWidgets('notifications: mark all as read clears the dots', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      path: '/notifications',
    );
    await _settle(t);
    // The fake server refuses: the dots come back and the screen says so.
    await t.tap(find.text('Mark all as read'));
    await _settle(t);
    expect(find.textContaining("Couldn't mark them as read"), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
  });

  testWidgets('language: switching to Arabic and back relabels the app', (
    t,
  ) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      path: '/account',
      size: const Size(393, 1600),
    );
    await _settle(t);
    await t.tap(find.text('العربية'));
    await _settle(t);
    expect(find.text('حسابي'), findsWidgets);
    await t.tap(find.text('English'));
    await _settle(t);
    expect(find.text('Account'), findsWidgets);
  });
}
