import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/features/player/playback_speed.dart';
import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_catalog.dart';
import 'fake_learning.dart';
import 'fake_video.dart';
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

  group('course ratings', () {
    test('the summary reads every star, missing ones as zero', () {
      final r = RatingSummary.fromJson({
        'averageRating': 4.5,
        'totalReviews': 2,
        'distribution': {'5': 1, '4': 1},
      });
      expect(r.distribution, {1: 0, 2: 0, 3: 0, 4: 1, 5: 1});
    });

    testWidgets('the catalog shows each rated course\'s rating', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/catalog',
        catalog: RatedCatalog(),
      );
      expect(find.text('٤٫٦'), findsOneWidget);
      expect(find.text('٤٫٢'), findsOneWidget);
      expect(find.text('(٢٣)'), findsOneWidget);
    });

    testWidgets('the preview shows the reviews and opens all of them', (
      t,
    ) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/catalog/free-algebra',
        size: const Size(393, 2600),
        catalog: RatedCatalog(),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('تقييمات الطلاب'), findsOneWidget);
      expect(find.text('مريم حسن'), findsOneWidget);
      expect(find.text('طالب'), findsOneWidget); // no name given
      await t.tap(find.text('عرض كل التقييمات'));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Omar Khaled'), findsOneWidget);
    });

    testWidgets('a course without reviews shows no reviews section', (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/catalog/free-english',
        size: const Size(393, 2600),
        catalog: RatedCatalog(),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('تقييمات الطلاب'), findsNothing);
    });
  });

  testWidgets('the chosen speed is shown and kept for the next lesson', (
    t,
  ) async {
    VideoPlayerPlatform.instance = FakeVideo();
    final container = await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/lesson/l2',
      learning: _VideoLesson(),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('السرعة ١×'), findsOneWidget);
    await t.tap(find.text('السرعة ١×'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('١٫٥×'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('السرعة ١٫٥×'), findsOneWidget);
    expect(container.read(playbackSpeedProvider), 1.5);
    expect(
      container.read(sharedPreferencesProvider).getDouble('player.speed'),
      1.5,
    );
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
  Future<void> undoCompleteLesson(
    String courseId,
    String lessonId, {
    String? opId,
    int? clientOpAt,
  }) async => undone.add('$courseId/$lessonId');
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

/// A lesson whose video is uploaded to Atlas.
class _VideoLesson extends FakeLearningRepository {
  @override
  Future<LessonGrant> grant(String courseId, String lessonId) async =>
      LessonGrant.fromJson({
        'lessonId': lessonId,
        'courseId': courseId,
        'title': 'درس فيديو',
        'kind': 'video',
        'completionRule': 'manual',
        'video': {'format': 'mp4', 'url': 'https://videos.example.test/v.mp4'},
        'watermark': {'enabled': true, 'code': '6SG7A-QKN29'},
        'playbackLease': null,
      });
}
