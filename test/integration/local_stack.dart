// Shared setup for the integration tests that run against the LOCAL stack
// (atlas-backend/scripts/e2e-local-stack.sh). Never point these at
// production: they register learners and author courses.
//
// Env: ATLAS_SPIKE_ORIGIN, ATLAS_SPIKE_ACADEMY_ID, ATLAS_SPIKE_OTP_ENV,
// ATLAS_SPIKE_OWNER_EMAIL, ATLAS_SPIKE_OWNER_PASSWORD.
import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

final _env = Platform.environment;

String get localAcademyId => _env['ATLAS_SPIKE_ACADEMY_ID']!;

AcademyEndpoint get localAcademy =>
    AcademyEndpoint.parse(_env['ATLAS_SPIKE_ORIGIN']!);

/// A fresh learner, signed in on the academy host like the app.
Future<({AtlasApiClient client, String userId})> newLocalLearner(
  String label,
) async {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final email = '$label-$stamp@example.test';
  const password = 'Probe-Passw0rd!x';
  final client = AtlasApiClient(
    endpoint: localAcademy,
    cookieJar: CookieJar(),
    userAgent: 'AtlasApp/0.4 (iPhone; iOS 18.0)',
  );
  final auth = AuthRepository(client, academyId: localAcademyId);
  await auth.register(
    name: 'Probe Learner',
    email: email,
    password: password,
    phoneNumber: '011${(stamp % 100000000).toString().padLeft(8, '0')}',
    phoneCountry: 'EG',
  );
  var outcome = await auth.signIn(email: email, password: password);
  if (outcome is EmailCodeRequired) {
    final r = await Process.run('node', [
      'tool/local_stack/force_otp_code.mjs',
      _env['ATLAS_SPIKE_OTP_ENV']!,
      email,
      '135790',
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    outcome = await auth.verifyEmailCode(
      challengeId: outcome.challengeId,
      code: '135790',
      rememberDevice: false,
    );
  }
  return (client: client, userId: (outcome as SignedIn).user['id'] as String);
}

/// The seed owner on the management surface.
Future<AtlasApiClient> localStaff() async {
  final platform = AcademyEndpoint.parse(
    'http://localhost:${localAcademy.origin.port}',
  );
  final staff = AtlasApiClient(
    endpoint: platform,
    cookieJar: CookieJar(),
    userAgent: 'probe-staff',
  );
  final s = await staff.post<Map<String, dynamic>>(
    'auth/sign-in',
    data: {
      'email': _env['ATLAS_SPIKE_OWNER_EMAIL'],
      'password': _env['ATLAS_SPIKE_OWNER_PASSWORD'],
      'surface': 'management',
    },
  );
  staff.setAccessToken(s['accessToken'] as String?);
  return staff;
}

/// A published course with one text lesson, a quiz with every question
/// type, an assignment, and a certificate on completion of all three.
Future<({String courseId, String lessonId, String quizId, String assignmentId})>
authorAssessedCourse(AtlasApiClient staff, {String integrity = 'warn'}) async {
  final a = localAcademyId;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final course = await staff.post<Map<String, dynamic>>(
    'academies/$a/courses',
    data: {
      'title': 'أساسيات الجبر $stamp',
      'slug': 'algebra-$stamp',
      'pricing': {'type': 'free'},
      'visibility': 'private',
      'language': 'ar',
    },
  );
  final courseId = course['id'] as String;
  final section = await staff.post<Map<String, dynamic>>(
    'academies/$a/courses/$courseId/sections',
    data: {'title': 'الوحدة الأولى'},
  );
  final sectionId = section['id'] as String;
  final lesson = await staff.post<Map<String, dynamic>>(
    'academies/$a/courses/$courseId/sections/$sectionId/lessons',
    data: {
      'title': 'المعادلات من الدرجة الأولى',
      'contentType': 'text',
      'status': 'published',
    },
  );
  final lessonId = lesson['id'] as String;
  await staff.put<dynamic>(
    'academies/$a/courses/$courseId/sections/$sectionId/lessons/$lessonId/content',
    data: {'kind': 'text', 'bodyHtml': '<p>س + ٢ = ٥</p>'},
  );
  final quiz = await staff.post<Map<String, dynamic>>(
    'courses/$courseId/quizzes',
    data: {
      'title': 'اختبار الوحدة الأولى',
      'description': 'أجب عن كل الأسئلة.',
      'sectionId': sectionId,
      'status': 'published',
      'passingScore': 50,
      'maxAttempts': 3,
      'timeLimitSeconds': 600,
      'integrityMode': integrity,
      'maxViolations': 3,
      'showScore': 'immediately',
      'showAnswers': 'immediately',
      'showExplanations': true,
      'layout': 'one_per_page',
      'requiredForCompletion': true,
      'questions': [
        {
          'prompt': 'ما قيمة س في س + ٢ = ٥؟',
          'type': 'single_choice',
          'points': 2,
          'explanation': 'نطرح ٢ من الطرفين.',
          'options': [
            {'label': '٣', 'isCorrect': true},
            {'label': '٧', 'isCorrect': false},
          ],
        },
        {
          'prompt': 'أي مما يلي أعداد زوجية؟',
          'type': 'multiple_choice',
          'points': 2,
          'options': [
            {'label': '٢', 'isCorrect': true},
            {'label': '٣', 'isCorrect': false},
            {'label': '٤', 'isCorrect': true},
          ],
        },
        {
          'prompt': 'الصفر عدد زوجي.',
          'type': 'true_false',
          'points': 1,
          'options': [
            {'label': 'صح', 'isCorrect': true},
            {'label': 'خطأ', 'isCorrect': false},
          ],
        },
        {
          'prompt': 'اكتب ناتج ٢ × ٣ بالحروف.',
          'type': 'short_answer',
          'points': 1,
          'acceptedAnswers': ['ستة', 'six'],
        },
      ],
    },
  );
  final quizId = quiz['id'] as String;
  final assignment = await staff.post<Map<String, dynamic>>(
    'courses/$courseId/assignments',
    data: {
      'title': 'واجب: حل خمس معادلات',
      'instructions': 'حل المعادلات في الملزمة وارفع صورة الحل.',
      'sectionId': sectionId,
      'status': 'published',
      'dueAt': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'allowResubmission': true,
      'latePolicy': 'accept_flagged',
      'requiredForCompletion': true,
    },
  );
  final assignmentId = assignment['id'] as String;
  for (final item in [
    {'type': 'quiz', 'itemId': quizId},
    {'type': 'assignment', 'itemId': assignmentId},
  ]) {
    try {
      await staff.post<dynamic>(
        'academies/$a/courses/$courseId/sections/$sectionId/items/attach',
        data: item,
      );
    } on Object {
      // Already placed by sectionId.
    }
  }
  await staff.put<dynamic>(
    'academies/$a/courses/$courseId/completion-rule',
    data: {
      'lessons': 'all',
      'requiredQuizIds': [quizId],
      'requiredAssignmentIds': [assignmentId],
      'certificatesEnabled': true,
    },
  );
  await staff.post<dynamic>('academies/$a/courses/$courseId/publish');
  return (
    courseId: courseId,
    lessonId: lessonId,
    quizId: quizId,
    assignmentId: assignmentId,
  );
}
