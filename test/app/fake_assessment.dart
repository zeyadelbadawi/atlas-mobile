import 'package:atlas_mobile/core/api/academy_endpoint.dart';

import '../design/golden_harness.dart' show testNow;

import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/core/learning/assessment_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';

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

  static const _questions = [
    {
      'id': 'q1',
      'type': 'single_choice',
      'prompt': 'ما قيمة النهاية عندما تقترب س من ٢ للدالة د(س) = س² + ١؟',
      'points': 2,
      'options': [
        {'id': 'o1', 'label': '٣'},
        {'id': 'o2', 'label': '٥'},
        {'id': 'o3', 'label': 'غير موجودة'},
      ],
    },
    {
      'id': 'q2',
      'type': 'multiple_choice',
      'prompt': 'أي الدوال التالية متصلة عند س = ٠؟',
      'points': 2,
      'options': [
        {'id': 'o4', 'label': 'د(س) = س²'},
        {'id': 'o5', 'label': 'د(س) = ١ ÷ س'},
        {'id': 'o6', 'label': 'د(س) = |س|'},
      ],
    },
    {
      'id': 'q3',
      'type': 'short_answer',
      'prompt': 'اكتب اسم القاعدة المستخدمة في حالة ٠ ÷ ٠.',
      'points': 1,
      'options': <Map>[],
    },
  ];

  @override
  Future<Quiz> quiz(String courseId, String quizId) async => Quiz.fromJson({
    'id': quizId,
    'courseId': courseId,
    'title': 'اختبار الوحدة الأولى: النهايات',
    'description': 'ثلاثة أسئلة عن النهايات والاتصال. راجع درس «النهايات من جهة واحدة» قبل البدء.',
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
        'explanation': 'نعوّض مباشرة: ٢² + ١ = ٥.',
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
        'title': 'واجب: تمارين النهايات',
        'instructions': 'حل التمارين من ١ إلى ٥ في الملزمة، ثم صوّر الحل وارفعه هنا. اكتب الناتج النهائي لكل تمرين في خانة الإجابة.',
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
    'response': '١) ٥  ٢) ٠  ٣) غير موجودة  ٤) ٢  ٥) ١',
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
        'feedback':
            'حل ممتاز. راجع التمرين الثالث: النهاية موجودة من جهة اليمين فقط.',
        'gradedAt': _now.toIso8601String(),
      },
  });

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
        'courseTitle': 'التفاضل والتكامل: الصف الثالث الثانوي',
        'quizResults': [
          {
            'quizId': 'l3',
            'quizTitle': 'اختبار الوحدة الأولى: النهايات',
            'attemptNumber': 2,
            'score': 80,
            'passed': true,
            'submittedAt': _now.toIso8601String(),
          },
          {
            'quizId': 'l7',
            'quizTitle': 'اختبار قصير: الاتصال',
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
            'assignmentTitle': 'واجب: تمارين النهايات',
            'gradingStatus': 'graded',
            'score': 9,
            'hasFeedback': true,
            'submittedAt': _now.toIso8601String(),
          },
          {
            'assignmentId': 'l9',
            'assignmentTitle': 'واجب: رسم الدوال',
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
            'courseTitle': 'الفيزياء: الكهربية الحديثة',
            'serial': 'ZIA-2026-000014',
            'verificationCode': '7K2QH9TMX4RB',
            'verificationCodeDisplay': '7K2Q-H9TM-X4RB',
            'status': 'issued',
            'renderStatus': 'ready',
            'issuedAt': _now.toIso8601String(),
            'overallScore': 91,
            'learnerNameOnCertificate': 'زياد البدوي',
          },
          {
            'id': 'cert2',
            'courseId': 'c-chem',
            'courseTitle': 'الكيمياء العضوية',
            'serial': 'ZIA-2026-000015',
            'verificationCode': 'P8W3N6ZC2LFA',
            'verificationCodeDisplay': 'P8W3-N6ZC-2LFA',
            'status': 'issued',
            'renderStatus': 'pending',
            'issuedAt': _now.toIso8601String(),
            'learnerNameOnCertificate': 'زياد البدوي',
          },
        ],
      });
}
