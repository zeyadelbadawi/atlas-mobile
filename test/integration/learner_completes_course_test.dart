// Phase 3 exit check against the LOCAL stack: a new learner, enrolled by
// staff, finishes a whole course through the app's LearningRepository.
// Same env as lesson_grant_spike_test.dart.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  final env = Platform.environment;
  const keys = [
    'ATLAS_SPIKE_ORIGIN',
    'ATLAS_SPIKE_ACADEMY_ID',
    'ATLAS_SPIKE_COURSE_ID',
    'ATLAS_SPIKE_OTP_ENV',
    'ATLAS_SPIKE_OWNER_EMAIL',
    'ATLAS_SPIKE_OWNER_PASSWORD',
  ];
  final missing = keys.where((k) => env[k] == null).toList();

  test(
    'a learner finishes a course through the app repository',
    () async {
      final academyId = env['ATLAS_SPIKE_ACADEMY_ID']!;
      final courseId = env['ATLAS_SPIKE_COURSE_ID']!;
      final academy = AcademyEndpoint.parse(env['ATLAS_SPIKE_ORIGIN']!);
      final platform = AcademyEndpoint.parse(
        'http://localhost:${academy.origin.port}',
      );
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'finish-$stamp@example.test';
      const password = 'Finish-Passw0rd!x';
      final client = AtlasApiClient(
        endpoint: academy,
        cookieJar: CookieJar(),
        userAgent: 'AtlasApp/0.3 (Android)',
      );
      final auth = AuthRepository(client, academyId: academyId);
      await auth.register(
        name: 'Finish Learner',
        email: email,
        password: password,
        phoneNumber: '015${(stamp % 100000000).toString().padLeft(8, '0')}',
        phoneCountry: 'EG',
      );
      var outcome = await auth.signIn(email: email, password: password);
      if (outcome is EmailCodeRequired) {
        final r = await Process.run('node', [
          'tool/local_stack/force_otp_code.mjs',
          env['ATLAS_SPIKE_OTP_ENV']!,
          email,
          '246802',
        ]);
        expect(r.exitCode, 0, reason: '${r.stderr}');
        outcome = await auth.verifyEmailCode(
          challengeId: outcome.challengeId,
          code: '246802',
          rememberDevice: true,
        );
      }
      final userId = (outcome as SignedIn).user['id'] as String;
      final staff = AtlasApiClient(
        endpoint: platform,
        cookieJar: CookieJar(),
        userAgent: 'staff',
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
      await staff.post<dynamic>(
        'academies/$academyId/students/$userId/enrollments',
        data: {'courseId': courseId},
      );

      final repo = LearningRepository(client);
      final courses = await repo.enrollments();
      expect(courses.map((c) => c.courseId), contains(courseId));

      var seq = await repo.sequence(courseId);
      expect(seq.items, isNotEmpty);
      var guard = 0;
      while (!seq.finished && guard++ < 50) {
        final item = seq.continueItem!;
        expect(item.isLesson, isTrue, reason: 'this course has lessons only');
        final grant = await repo.grant(courseId, item.id);
        expect(grant.lessonId, item.id);
        expect(['text', 'video', 'file', 'external'], contains(grant.kind));
        await repo.completeLesson(courseId, item.id);
        seq = await repo.sequence(courseId);
      }
      expect(seq.finished, isTrue);
      final completion = await repo.completion(courseId);
      expect(completion.completed, isTrue);
      final overview = await repo.overview();
      expect(overview.allCourses, greaterThanOrEqualTo(1));
      final devices = await repo.devices();
      expect(devices.devices.where((d) => d.current), hasLength(1));
      expect(devices.devices.single.label, 'Atlas app on Android');
    },
    skip: missing.isEmpty ? null : 'missing ${missing.join(', ')}',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
