// Prints the learning API's real response shapes from the LOCAL stack (phase
// 3 reference). Same env as lesson_grant_spike_test.dart, plus
// ATLAS_PROBE_OUT=<file> for the JSON dump.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  final env = Platform.environment;
  final skip = env['ATLAS_PROBE_OUT'] == null ? 'probe not requested' : null;

  test(
    'learning shapes',
    () async {
      final academyId = env['ATLAS_SPIKE_ACADEMY_ID']!;
      final courseId = env['ATLAS_SPIKE_COURSE_ID']!;
      final academy = AcademyEndpoint.parse(env['ATLAS_SPIKE_ORIGIN']!);
      final platform = AcademyEndpoint.parse(
        'http://localhost:${academy.origin.port}',
      );
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'probe-$stamp@example.test';
      const password = 'Probe-Passw0rd!x';
      final learner = AtlasApiClient(
        endpoint: academy,
        cookieJar: CookieJar(),
        userAgent: 'AtlasApp/0.2 (iPhone; iOS 18.0)',
      );
      final auth = AuthRepository(learner, academyId: academyId);
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
          env['ATLAS_SPIKE_OTP_ENV']!,
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
      final userId = (outcome as SignedIn).user['id'] as String;
      final staff = AtlasApiClient(
        endpoint: platform,
        cookieJar: CookieJar(),
        userAgent: 'probe-staff',
      );
      final s = await staff.post<Map<String, dynamic>>(
        'auth/sign-in',
        data: {
          'email': env['ATLAS_SPIKE_OWNER_EMAIL'],
          'password': env['ATLAS_SPIKE_OWNER_PASSWORD'],
          'surface': 'management',
        },
      );
      staff.setAccessToken(s['accessToken'] as String?);

      final out = <String, Object?>{};
      Future<void> grab(String name, Future<Object?> Function() call) async {
        try {
          out[name] = await call();
        } on AtlasApiException catch (e) {
          out[name] = {'ERROR': e.toString(), 'fields': e.fields};
        }
      }

      await grab(
        'overview_before',
        () => learner.get<dynamic>('learning/overview'),
      );
      await grab(
        'courses_catalog',
        () => learner.get<dynamic>('courses', query: {'limit': 5}),
      );
      await staff.post<dynamic>(
        'academies/$academyId/students/$userId/enrollments',
        data: {'courseId': courseId},
      );
      await grab('enrollments', () => learner.get<dynamic>('enrollments'));
      await grab(
        'enrollment_by_course',
        () => learner.get<dynamic>('enrollments/by-course/$courseId'),
      );
      await grab('course', () => learner.get<dynamic>('courses/$courseId'));
      await grab(
        'sections',
        () => learner.get<dynamic>('courses/$courseId/sections'),
      );
      await grab(
        'progress',
        () => learner.get<dynamic>('courses/$courseId/progress'),
      );
      await grab(
        'completion',
        () => learner.get<dynamic>('learning/courses/$courseId/completion'),
      );
      final seq = await learner.get<Map<String, dynamic>>(
        'learning/courses/$courseId/sequence',
      );
      out['sequence'] = seq;
      final items = (seq['items'] as List).cast<Map>();
      for (final it in items.take(4)) {
        await grab(
          'content_${it['position']}_${it['state']}',
          () => learner.get<dynamic>(
            'learning/courses/$courseId/lessons/${it['id']}/content',
          ),
        );
        await grab(
          'complete_${it['position']}',
          () => learner.post<dynamic>(
            'courses/$courseId/progress/complete-lesson',
            data: {'lessonId': it['id']},
          ),
        );
      }
      await grab(
        'sequence_after',
        () => learner.get<dynamic>('learning/courses/$courseId/sequence'),
      );
      await grab(
        'overview_after',
        () => learner.get<dynamic>('learning/overview'),
      );
      await grab(
        'completion_after',
        () => learner.get<dynamic>('learning/courses/$courseId/completion'),
      );
      await grab('devices', () => learner.get<dynamic>('learning/devices'));
      await grab('quizzes', () => learner.get<dynamic>('learning/quizzes'));
      await grab(
        'assignments',
        () => learner.get<dynamic>('learning/assignments'),
      );
      File(env['ATLAS_PROBE_OUT']!)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
