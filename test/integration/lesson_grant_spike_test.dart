// Phase 0 spike: a learner opens a YouTube lesson — grant, device slot,
// watermark code, playback lease — against the LOCAL stack.
//
//   ATLAS_SPIKE_ORIGIN=http://web-development-academy:3000 \
//   ATLAS_SPIKE_ACADEMY_ID=<academy> ATLAS_SPIKE_COURSE_ID=<course> \
//   ATLAS_SPIKE_LESSON_ID=<youtube lesson> ATLAS_SPIKE_OTP_ENV=<backend.env> \
//   ATLAS_SPIKE_OWNER_EMAIL=<seeded owner> ATLAS_SPIKE_OWNER_PASSWORD=<dev password> \
//   flutter test test/integration/lesson_grant_spike_test.dart
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/api/secure_cookie_storage.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  final env = Platform.environment;
  const keys = [
    'ATLAS_SPIKE_ORIGIN',
    'ATLAS_SPIKE_ACADEMY_ID',
    'ATLAS_SPIKE_COURSE_ID',
    'ATLAS_SPIKE_LESSON_ID',
    'ATLAS_SPIKE_OTP_ENV',
    'ATLAS_SPIKE_OWNER_EMAIL',
    'ATLAS_SPIKE_OWNER_PASSWORD',
  ];
  final missing = keys.where((k) => env[k] == null).toList();
  final skip = missing.isEmpty ? null : 'missing ${missing.join(', ')}';

  test(
    'enrolled learner gets a watermarked YouTube grant and a lease',
    () async {
      final academyId = env['ATLAS_SPIKE_ACADEMY_ID']!;
      final courseId = env['ATLAS_SPIKE_COURSE_ID']!;
      final lessonId = env['ATLAS_SPIKE_LESSON_ID']!;
      final academy = AcademyEndpoint.parse(env['ATLAS_SPIKE_ORIGIN']!);
      final platform = AcademyEndpoint.parse(
        'http://localhost:${academy.origin.port}',
      );

      // Learner: register + sign in (+ code if the stack asks for one).
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'grant-$stamp@example.test';
      const password = 'Spike-Passw0rd!x';
      final learner = AtlasApiClient(
        endpoint: academy,
        cookieJar: PersistCookieJar(storage: MemoryCookieStorage()),
        userAgent: 'AtlasApp/0.1 (iPhone; iOS 18.0) Dart',
      );
      final auth = AuthRepository(learner, academyId: academyId);
      await auth.register(
        name: 'Grant Learner',
        email: email,
        password: password,
        phoneNumber: '012${(stamp % 100000000).toString().padLeft(8, '0')}',
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
      expect(outcome, isA<SignedIn>());
      final userId = (outcome as SignedIn).user['id'] as String;

      // Staff enrols the learner (stands in for "bought it on the website").
      final staff = AtlasApiClient(
        endpoint: platform,
        cookieJar: CookieJar(),
        userAgent: 'spike-staff',
      );
      final staffSignIn = await staff.post<Map<String, dynamic>>(
        'auth/sign-in',
        data: {
          'email': env['ATLAS_SPIKE_OWNER_EMAIL'],
          'password': env['ATLAS_SPIKE_OWNER_PASSWORD'],
          'surface': 'management',
        },
      );
      staff.setAccessToken(staffSignIn['accessToken'] as String?);
      await staff.post<dynamic>(
        'academies/$academyId/students/$userId/enrollments',
        data: {'courseId': courseId},
      );

      final sequence = await learner.get<dynamic>(
        'learning/courses/$courseId/sequence',
      );
      _show('sequence', sequence);

      // The video lesson is locked behind the first one ("previousIncomplete").
      final first = ((sequence as Map)['items'] as List).first as Map;
      await learner.get<dynamic>(
        'learning/courses/$courseId/lessons/${first['id']}/content',
      );
      await learner.post<dynamic>(
        'courses/$courseId/progress/complete-lesson',
        data: {'lessonId': first['id']},
      );

      final grant = await learner.get<Map<String, dynamic>>(
        'learning/courses/$courseId/lessons/$lessonId/content',
      );
      _show('lesson content grant', grant);
      final text = jsonEncode(grant);
      expect(
        text,
        contains('youtube'),
        reason: 'YouTube lesson becomes an embed',
      );
      expect(
        RegExp(r'[0-9A-HJKMNP-TV-Z]{5}-[0-9A-HJKMNP-TV-Z]{5}').hasMatch(text),
        isTrue,
        reason: 'a per-viewer watermark code is in the grant',
      );

      final devices = await learner.get<dynamic>('learning/devices');
      _show('devices', devices);

      final leaseId = _find(grant, 'leaseId') as String?;
      final beat = await learner.post<dynamic>(
        'learning/courses/$courseId/playback',
        data: {
          'lessonId': lessonId,
          'positionSeconds': 12,
          'leaseId': ?leaseId,
        },
      );
      _show('heartbeat', beat);
      if (leaseId != null) {
        await learner.post<dynamic>(
          'learning/courses/$courseId/playback/release',
          data: {'leaseId': leaseId},
        );
      }
    },
    skip: skip,
  );
}

Object? _find(Object? node, String key) {
  if (node is Map) {
    if (node.containsKey(key)) return node[key];
    for (final v in node.values) {
      final hit = _find(v, key);
      if (hit != null) return hit;
    }
  } else if (node is List) {
    for (final v in node) {
      final hit = _find(v, key);
      if (hit != null) return hit;
    }
  }
  return null;
}

void _show(String label, Object? value) {
  final text = const JsonEncoder.withIndent('  ').convert(value);
  // Shapes only, for the spike report; local throwaway data.
  stdout.writeln(
    '--- $label\n${text.length > 2500 ? '${text.substring(0, 2500)}…' : text}',
  );
}
