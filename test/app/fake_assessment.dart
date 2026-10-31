import 'package:atlas_mobile/core/api/academy_endpoint.dart';

import '../design/golden_harness.dart' show testNow;

import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/core/learning/assessment_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'demo_text.dart';

enum QuizStage { intro, running, results }

/// Sample assessments for screen goldens (illustrative, not real learners).
class FakeAssessmentRepository extends AssessmentRepository {
  FakeAssessmentRepository({this.stage = QuizStage.intro, this.graded = true})
    : super(
        AtlasApiClient(
          endpoint: AcademyEndpoint.parse('ziadd.atlass.dpdns.org'),
          cookieJar: CookieJar(),
          userAgent: 'test',
        ),
      );

  final QuizStage stage;
  final bool graded;

  static final _now = testNow.toUtc();

  // A getter, not a constant: the English store run switches the text.
  static List<Map<String, dynamic>> get _questions => [
    {
      'id': 'q1',
      'type': 'single_choice',
      'prompt': demo(
        'ما قيمة النهاية عندما تقترب س من ٢ للدالة د(س) = س² + ١؟',
      ),
      'points': 2,
      'options': [
        {'id': 'o1', 'label': demo('٣')},
        {'id': 'o2', 'label': demo('٥')},
        {'id': 'o3', 'label': demo('غير موجودة')},
      ],
    },
    {
      'id': 'q2',
      'type': 'multiple_choice',
      'prompt': demo('أي الدوال التالية متصلة عند س = ٠؟'),
      'points': 2,
      'options': [
        {'id': 'o4', 'label': demo('د(س) = س²')},
        {'id': 'o5', 'label': demo('د(س) = ١ ÷ س')},
        {'id': 'o6', 'label': demo('د(س) = |س|')},
      ],
    },
    {
      'id': 'q3',
      'type': 'short_answer',
      'prompt': demo('اكتب اسم القاعدة المستخدمة في حالة ٠ ÷ ٠.'),
      'points': 1,
      'options': <Map>[],
    },
  ];

  @override
  Future<Quiz> quiz(String courseId, String quizId) async => Quiz.fromJson({
    'id': quizId,
    'courseId': courseId,
    'title': demo('اختبار الوحدة الأولى: النهايات'),
    'description': demo(
      'ثلاثة أسئلة عن النهايات والاتصال. راجع درس «النهايات من جهة واحدة» قبل البدء.',
    ),
    'questionCount': 3,
    'passingScore': 60,
    'attemptsAllowed': 3,
    'settings': {
      'timeLimitSeconds': 900,
      'dueAt': _now.add(const Duration(days: 2)).toIso8601String(),
      'gradingPolicy': 'highest',
      'layout': 'one_per_page',
      'integrityMode': 'warn',
      'maxViolations': 3,
      'showScore': 'immediately',
      'showAnswers': 'immediately',
    },
    'questions': _questions,
  });

  @override
  Future<List<QuizAttempt>> attempts(String courseId, String quizId) async =>
      switch (stage) {
        QuizStage.intro => const [],
        QuizStage.running => [
          QuizAttempt.fromJson({
            'id': 'a1',
            'status': 'in_progress',
            'attemptNumber': 1,
          }),
        ],
        QuizStage.results => [
          QuizAttempt.fromJson({
            'id': 'a2',
            'status': 'passed',
            'attemptNumber': 2,
            'score': 80,
            'submittedAt': _now.toIso8601String(),
          }),
          QuizAttempt.fromJson({
            'id': 'a1',
            'status': 'failed',
            'attemptNumber': 1,
            'score': 40,
            'submittedAt': _now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          }),
        ],
      };

  @override
  Future<QuizSession> session(
    String courseId,
    String quizId,
    String attemptId,
  ) async => QuizSession.fromJson({
    'attemptId': attemptId,
    'status': 'in_progress',
    'attemptNumber': 1,
    'serverNow': _now.toIso8601String(),
    'deadlineAt': _now
        .add(const Duration(minutes: 12, seconds: 5))
        .toIso8601String(),
    'revision': 2,
    'settings': {
      'layout': 'one_per_page',
      'integrityMode': 'off',
      'timeLimitSeconds': 900,
    },
    'questions': _questions,
    'answers': [
      {
        'questionId': 'q1',
        'selectedOptionIds': ['o2'],
      },
    ],
  });

  @override
  Future<QuizResults> results(
    String courseId,
    String quizId,
    String attemptId,
  ) async => QuizResults.fromJson({
    'attemptId': attemptId,
    'status': 'passed',
    'attemptNumber': 2,
    'submittedAt': _now.toIso8601String(),
    'disclosure': {'score': true, 'answers': true, 'explanations': true},
    'score': 80,
    'passed': true,
    'pointsEarned': 4,
    'pointsTotal': 5,
    'passingScore': 60,
    'effectiveScore': 80,
    'canRetry': true,
    'attemptsUsed': 2,
    'attemptsAllowed': 3,
    'questions': [
      {
        'questionId': 'q1',
        'prompt': _questions[0]['prompt'],
        'type': 'single_choice',
        'points': 2,
        'answered': true,
        'correct': true,
        'pointsAwarded': 2,
        'yourAnswer': {
          'questionId': 'q1',
          'selectedOptionIds': ['o2'],
        },
        'correctOptionIds': ['o2'],
        'explanation': demo('نعوّض مباشرة: ٢² + ١ = ٥.'),
      },
      {
        'questionId': 'q2',
        'prompt': _questions[1]['prompt'],
        'type': 'multiple_choice',
        'points': 2,
        'answered': true,
        'correct': false,
        'pointsAwarded': 1,
        'yourAnswer': {
          'questionId': 'q2',
          'selectedOptionIds': ['o4'],
        },
        'correctOptionIds': ['o4', 'o6'],
      },
    ],
  });

  @override
  Future<Assignment> assignment(String courseId, String id) async =>
      Assignment.fromJson({
        'id': id,
        'courseId': courseId,
        'title': demo('واجب: تمارين النهايات'),
        'instructions': demo(
          'حل التمارين من ١ إلى ٥ في الملزمة، ثم صوّر الحل وارفعه هنا. اكتب الناتج النهائي لكل تمرين في خانة الإجابة.',
        ),
        'dueAt': _now.add(const Duration(days: 3)).toIso8601String(),
        'allowResubmission': true,
        'latePolicy': 'accept_flagged',
      });

  @override
  Future<AssignmentSubmission?> submission(
    String courseId,
    String id,
  ) async => AssignmentSubmission.fromJson({
    'id': 's1',
    'status': 'submitted',
    'response': demo('١) ٥  ٢) ٠  ٣) غير موجودة  ٤) ٢  ٥) ١'),
    'attachment': {
      'assetId': 'f1',
      'fileName': 'solution.jpg',
      'mimeType': 'image/jpeg',
      'sizeBytes': 842000,
      'url': 'https://example.com/x',
    },
    'submittedAt': _now.subtract(const Duration(hours: 5)).toIso8601String(),
    'submittedRevision': 1,
    'gradingStatus': graded ? 'graded' : 'ungraded',
    if (graded)
      'grade': {
        'score': 9,
        'feedback': demo(
          'حل ممتاز. راجع التمرين الثالث: النهاية موجودة من جهة اليمين فقط.',
        ),
        'gradedAt': _now.toIso8601String(),
      },
  });

  @override
  Future<List<LearnerTask>> tasks() async {
    String at(Duration d) => testNow.add(d).toUtc().toIso8601String();
    Map<String, dynamic> t(
      String id,
      String type,
      String title,
      String course,
      String state, {
      Duration? due,
      Duration? submitted,
      num? score,
    }) => {
      'id': id,
      'type': type,
      'title': title,
      'courseId': 'c-calc',
      'courseTitle': course,
      'state': state,
      'dueAt': due == null ? null : at(due),
      'submittedAt': submitted == null ? null : at(submitted),
      'score': score,
    };
    return [
      t(
        'a1',
        'assignment',
        demo('واجب الاتصال'),
        demo('التفاضل والتكامل'),
        'not_started',
        due: const Duration(days: 3),
      ),
      t(
        'a0',
        'assignment',
        demo('تقرير المعمل'),
        demo('الفيزياء: الكهربية'),
        'overdue',
        due: const Duration(days: -2),
      ),
      t(
        'q1',
        'quiz',
        demo('كويز النهايات'),
        demo('التفاضل والتكامل'),
        'in_progress',
      ),
      t(
        'a2',
        'assignment',
        demo('مسائل الدوائر'),
        demo('الفيزياء: الكهربية'),
        'draft',
        due: const Duration(days: 6),
      ),
      t(
        'q2',
        'quiz',
        demo('اختبار الوحدة الأولى'),
        demo('الكيمياء العضوية'),
        'submitted',
        submitted: const Duration(hours: -5),
      ),
      t(
        'q3',
        'quiz',
        demo('كويز المشتقات'),
        demo('التفاضل والتكامل'),
        'passed',
        submitted: const Duration(days: -4),
        score: 91,
      ),
      t(
        'q4',
        'quiz',
        demo('كويز الروابط'),
        demo('الكيمياء العضوية'),
        'failed',
        submitted: const Duration(days: -6),
        score: 45,
      ),
      t(
        'a3',
        'assignment',
        demo('واجب الحدود'),
        demo('التفاضل والتكامل'),
        'graded',
        submitted: const Duration(days: -8),
        score: 18,
      ),
    ].map(LearnerTask.fromJson).toList();
  }

  @override
  Future<StudentResults> studentResults() async => StudentResults.fromJson({
    'summary': {
      'coursesEnrolled': 3,
      'coursesCompleted': 1,
      'quizzesAttempted': 4,
      'quizzesPassed': 3,
      'assignmentsSubmitted': 2,
      'averageQuizScore': 78,
    },
    'courses': [
      {
        'courseId': 'c-calc',
        'courseTitle': demo('التفاضل والتكامل: الصف الثالث الثانوي'),
        'quizResults': [
          {
            'quizId': 'l3',
            'quizTitle': demo('اختبار الوحدة الأولى: النهايات'),
            'attemptNumber': 2,
            'score': 80,
            'passed': true,
            'submittedAt': _now.toIso8601String(),
          },
          {
            'quizId': 'l7',
            'quizTitle': demo('اختبار قصير: الاتصال'),
            'attemptNumber': 1,
            'score': 45,
            'passed': false,
            'submittedAt': _now
                .subtract(const Duration(days: 4))
                .toIso8601String(),
          },
        ],
        'assignmentResults': [
          {
            'assignmentId': 'l6',
            'assignmentTitle': demo('واجب: تمارين النهايات'),
            'gradingStatus': 'graded',
            'score': 9,
            'hasFeedback': true,
            'submittedAt': _now.toIso8601String(),
          },
          {
            'assignmentId': 'l9',
            'assignmentTitle': demo('واجب: رسم الدوال'),
            'gradingStatus': 'ungraded',
            'submittedAt': _now.toIso8601String(),
          },
        ],
      },
    ],
  });

  @override
  Future<LearnerCertificates> certificates() async =>
      LearnerCertificates.fromJson({
        'enabled': true,
        'items': [
          {
            'id': 'cert1',
            'courseId': 'c-phys',
            'courseTitle': demo('الفيزياء: الكهربية الحديثة'),
            'serial': 'ZIA-2026-000014',
            'verificationCode': '7K2QH9TMX4RB',
            'verificationCodeDisplay': '7K2Q-H9TM-X4RB',
            'status': 'issued',
            'renderStatus': 'ready',
            'issuedAt': _now.toIso8601String(),
            'overallScore': 91,
            'learnerNameOnCertificate': demo('زياد البدوي'),
          },
          {
            'id': 'cert2',
            'courseId': 'c-chem',
            'courseTitle': demo('الكيمياء العضوية'),
            'serial': 'ZIA-2026-000015',
            'verificationCode': 'P8W3N6ZC2LFA',
            'verificationCodeDisplay': 'P8W3-N6ZC-2LFA',
            'status': 'issued',
            'renderStatus': 'pending',
            'issuedAt': _now.toIso8601String(),
            'learnerNameOnCertificate': demo('زياد البدوي'),
          },
        ],
      });
}
