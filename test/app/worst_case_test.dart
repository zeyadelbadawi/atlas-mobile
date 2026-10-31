@Tags(['golden'])
library;

import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

/// Worst-case data: very long Arabic and English names, a word with no
/// break points, a long email, four-digit counts. Every main screen, in
/// both languages, at normal and large text: nothing may overflow.
const _longAcademy = Academy(
  id: 'long',
  name: 'أكاديمية الدكتور عبد الرحمن للعلوم والرياضيات والفيزياء المتقدمة',
  host: 'abdelrahman-advanced-sciences-academy.atlass.dpdns.org',
  primaryColor: '160 60% 40%',
);

class _LongSession extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    academy: _longAcademy,
    user: {
      'name': 'عبد الرحمن محمد عبد العزيز إبراهيم الشناوي',
      'email': 'abdelrahman.mohamed.abdelaziz.elshenawy@students.example-university.edu.eg',
    },
  );
}

class _LongSignedOut extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedOut,
    academy: _longAcademy,
  );
}

const _longTitle =
    'الرياضيات البحتة والتطبيقية للصف الثالث الثانوي: التفاضل والتكامل والهندسة الفراغية';
const _unbroken =
    'Pneumonoultramicroscopicsilicovolcanoconiosis-Advanced-Edition';

class _LongLearning extends FakeLearningRepository {
  static EnrolledCourse _course(String id, String title, int done, int total) =>
      EnrolledCourse.fromJson({
        'id': 'e-$id',
        'courseId': id,
        'course': {
          'title': title,
          'instructors': [
            {'name': 'أ. د. عبد الرحمن محمد عبد العزيز الشناوي'},
            {'name': 'Dr. Alexandra Konstantinopoulou-Whitmore'},
          ],
        },
        'progress': {
          'completedItems': done,
          'totalItems': total,
          'percentage': done * 100 / total,
          'learningState': done == total ? 'completed' : 'in_progress',
        },
        'isActive': true,
      });

  @override
  Future<List<EnrolledCourse>> enrollments() async => [
    _course(FakeLearningRepository.courseId, _longTitle, 1234, 9999),
    _course('c-en', _unbroken, 0, 1),
    _course(
      'c-done',
      'Advanced Organic Chemistry and Biochemistry for Pre-Med',
      87,
      87,
    ),
  ];

  @override
  Future<LearnerOverview> overview() async => LearnerOverview.fromJson({
    'continueLearning': [
      {
        'courseId': FakeLearningRepository.courseId,
        'courseTitle': _longTitle,
        'percentage': 12.3,
        'completedItems': 1234,
        'totalItems': 9999,
        'nextItemId': 'l2',
        'nextItemTitle': _unbroken,
      },
    ],
    'courseCounts': {'all': 9999},
    'upcomingDeadlines': [
      {
        'id': 'd1',
        'type': 'assignment',
        'title': '$_longTitle — $_unbroken',
        'courseId': FakeLearningRepository.courseId,
        'courseTitle': _longTitle,
        'dueAt': testNow.add(const Duration(days: 2)).toIso8601String(),
        'overdue': false,
      },
    ],
    'announcements': const [],
  });

  @override
  Future<CourseSequence> sequence(String courseId) async {
    final json = Map<String, dynamic>.of(FakeLearningRepository.sequenceJson);
    json['courseTitle'] = _longTitle;
    json['completedCount'] = 1234;
    json['totalCount'] = 9999;
    return CourseSequence.fromJson(json);
  }
}

void main() {
  setUpAll(loadGoldenFonts);

  const course = FakeLearningRepository.courseId;
  final screens = <String, (SessionController Function(), String?)>{
    'sign-in': (_LongSignedOut.new, null),
    'home': (_LongSession.new, '/home'),
    'courses': (_LongSession.new, '/courses'),
    'course': (_LongSession.new, '/course/$course'),
    'lesson': (_LongSession.new, '/course/$course/lesson/l2'),
    'tasks': (_LongSession.new, '/tasks'),
    'account': (_LongSession.new, '/account'),
    'profile': (_LongSession.new, '/account/profile'),
  };

  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 1.6]) {
      for (final MapEntry(key: name, value: (session, path))
          in screens.entries) {
        testWidgets('$name $language x$scale', (t) async {
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpScreen(
            t,
            session: session,
            path: path,
            language: language,
            learning: _LongLearning(),
          );
          await t.pump(const Duration(seconds: 2));
          expect(t.takeException(), isNull);
        });
      }
    }
  }

  // Two pictures to look at, not just "no overflow".
  for (final (name, path) in [('home', '/home'), ('account', '/account')]) {
    testWidgets('worst_${name}_ar golden', (t) async {
      await pumpScreen(
        t,
        session: _LongSession.new,
        path: path,
        learning: _LongLearning(),
        size: const Size(393, 1300),
      );
      await t.pump(const Duration(seconds: 2));
      await expectGolden(
        t,
        find.byType(MaterialApp).first,
        'goldens/worst_${name}_ar.png',
      );
    });
  }
}
