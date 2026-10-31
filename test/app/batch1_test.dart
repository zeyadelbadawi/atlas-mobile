import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

/// Batch 1 of the features the web and backend already had.
void main() {
  setUpAll(loadGoldenFonts);

  group('course completion requirements', () {
    test('lessons the rule needs, as the server counts them', () {
      CourseCompletion rule(Object? lessons) => CourseCompletion.fromJson({
        'lessons': {'total': 8, 'completed': 3},
        'rule': {'lessons': lessons},
      });
      expect(rule('all').lessonsRequired, 8);
      expect(rule('none').lessonsRequired, 0);
      expect(rule(5).lessonsRequired, 5);
      expect(rule(20).lessonsRequired, 8);
      expect(rule(null).lessonsRequired, 8);
    });

    test('only required quizzes and assignments count', () {
      final k = CourseCompletion.fromJson({
        'quizzes': [
          {'quizId': 'q1', 'title': 'A', 'required': true, 'passed': true},
          {'quizId': 'q2', 'title': 'B', 'required': false},
          {
            'quizId': 'q3',
            'title': 'C',
            'required': true,
            'pendingGrading': true,
          },
        ],
        'assignments': [
          {'assignmentId': 'a1', 'title': 'D', 'required': true},
        ],
      });
      expect(k.quizzes.map((q) => q.state), [
        RequirementState.done,
        RequirementState.waiting,
      ]);
      expect(k.assignments.single.state, RequirementState.todo);
      expect(k.hasRequirementsBeyondLessons, isTrue);
    });

    testWidgets('every lesson done but a quiz not passed: not "completed"', (
      t,
    ) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/${FakeLearningRepository.courseId}',
        size: const Size(393, 1400),
        learning: _Course(completed: false),
      );
      expect(find.text('أكملت الكورس'), findsNothing);
      expect(find.text('متطلبات إنهاء الكورس'), findsOneWidget);
      expect(find.text('لم تنجح فيه بعد'), findsOneWidget);
    });

    testWidgets('the server says completed: the completed card', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/course/${FakeLearningRepository.courseId}',
        learning: _Course(completed: true),
      );
      expect(find.text('أكملت الكورس'), findsOneWidget);
      expect(find.text('متطلبات إنهاء الكورس'), findsNothing);
    });
  });

  testWidgets('a lesson marked done by mistake can be taken back', (t) async {
    final learning = _Undo();
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/lesson/l0',
      size: const Size(393, 1400),
      learning: learning,
    );
    await t.pump(const Duration(seconds: 1));
    await t.ensureVisible(find.text('إلغاء الإكمال'));
    await t.tap(find.text('إلغاء الإكمال'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(learning.undone, ['c-calc/l0']);
    expect(find.text('أُلغي إكمال الدرس.'), findsOneWidget);
    expect(find.text('أكملت الدرس'), findsOneWidget);
    expect(find.text('إلغاء الإكمال'), findsNothing);
  });
}

class _Undo extends FakeLearningRepository {
  final undone = <String>[];

  @override
  Future<void> undoCompleteLesson(String courseId, String lessonId) async =>
      undone.add('$courseId/$lessonId');
}

/// Every lesson done; the quiz passed only when [completed].
class _Course extends FakeLearningRepository {
  _Course({required this.completed});
  final bool completed;

  @override
  Future<CourseSequence> sequence(String courseId) async {
    final j = FakeLearningRepository.sequenceJson;
    for (final i in j['items'] as List) {
      (i as Map)['state'] = 'completed';
      i['lockReason'] = null;
    }
    j['completedCount'] = j['totalCount'];
    j['continueItemId'] = null;
    return CourseSequence.fromJson(j);
  }

  @override
  Future<CourseCompletion> completion(String courseId) async =>
      CourseCompletion.fromJson({
        'completed': completed,
        'lessons': {'total': 5, 'completed': 5},
        'rule': {'lessons': 'all'},
        'quizzes': [
          {
            'quizId': 'l3',
            'title': 'كويز النهايات',
            'required': true,
            'passed': completed,
          },
        ],
        'certificate': {'enabled': false},
      });
}
