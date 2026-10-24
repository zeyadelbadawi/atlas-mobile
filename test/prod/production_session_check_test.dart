// Read-mostly check of the session model on PRODUCTION, with an account the
// owner provided for testing. Never opens lessons (no device/lease churn).
//
// Two stages, because the emailed code comes from a person:
//   ATLAS_PROD_STAGE=signin   → signs in; stops at the emailed code and saves
//                                the challenge and cookies to ATLAS_PROD_STATE_DIR
//   ATLAS_PROD_STAGE=verify ATLAS_PROD_CODE=123456
//                              → completes the code, refreshes, reads /users/me,
//                                checks the device label, signs out
// Credentials come only from the environment (ATLAS_PROD_EMAIL/PASSWORD).
@Tags(['production'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  final env = Platform.environment;
  final stage = env['ATLAS_PROD_STAGE'];
  final dir = env['ATLAS_PROD_STATE_DIR'];
  final skip = stage == null || dir == null
      ? 'production check not requested'
      : null;

  test(
    'production session ($stage)',
    () async {
      final endpoint = AcademyEndpoint.parse(
        env['ATLAS_PROD_ORIGIN'] ?? 'ziadd.atlass.dpdns.org',
      );
      final jar = PersistCookieJar(storage: FileStorage('$dir/jar/'));
      final client = AtlasApiClient(
        endpoint: endpoint,
        cookieJar: jar,
        userAgent: 'AtlasApp/0.1-check (iPhone; iOS 18.0)',
      );
      final resolved = await client.get<Map<String, dynamic>>(
        'public/websites/resolve',
        query: {'hostname': endpoint.host},
      );
      final auth = AuthRepository(
        client,
        academyId: resolved['academyId'] as String,
      );
      final state = File('$dir/challenge.json');

      if (stage == 'signin') {
        final outcome = await auth.signIn(
          email: env['ATLAS_PROD_EMAIL']!,
          password: env['ATLAS_PROD_PASSWORD']!,
        );
        final names = (await jar.loadForRequest(endpoint.origin))
            .map((c) => c.name)
            .toList();
        stdout.writeln('cookies after sign-in: $names');
        if (outcome is EmailCodeRequired) {
          state.writeAsStringSync(
            jsonEncode({'challengeId': outcome.challengeId}),
          );
          stdout.writeln(
            'CODE_REQUIRED sent to ${outcome.maskedEmail}, '
            'expires ${outcome.expiresAt.toIso8601String()}',
          );
          return;
        }
        expect(outcome, isA<SignedIn>());
        stdout.writeln('SIGNED_IN without a code');
      } else {
        final challengeId =
            (jsonDecode(state.readAsStringSync()) as Map)['challengeId']
                as String;
        final outcome = await auth.verifyEmailCode(
          challengeId: challengeId,
          code: env['ATLAS_PROD_CODE']!,
          rememberDevice: false,
        );
        expect(outcome, isA<SignedIn>());
      }

      final cookies = await jar.loadForRequest(endpoint.origin);
      final session = cookies
          .where((c) => c.name == '__Host-atlas_session')
          .toList();
      expect(
        session,
        hasLength(1),
        reason: 'the secure host-only cookie is kept',
      );
      expect(session.single.secure, isTrue);

      final before = session.single.value;
      final refreshed = await client.refreshSession();
      final after = (await jar.loadForRequest(endpoint.origin))
          .firstWhere((c) => c.name == '__Host-atlas_session')
          .value;
      expect(after, isNot(before), reason: 'refresh rotates the cookie');
      expect(refreshed['user'], isA<Map<String, dynamic>>());

      final devices = await client.get<Map<String, dynamic>>(
        'learning/devices',
      );
      final current = (devices['devices'] as List).cast<Map>().where(
        (d) => d['current'] == true,
      );
      stdout.writeln(
        'device label: ${current.map((d) => d['label']).toList()}; '
        'limit ${devices['maxDevices']}, sessions ${devices['maxConcurrentSessions']}',
      );

      // Leave no device behind: remove this check's device, then sign out.
      for (final d in current) {
        try {
          await client.delete<dynamic>('learning/devices/${d['id']}');
          stdout.writeln('removed this check\'s device');
        } on Object catch (e) {
          stdout.writeln(
            'could not remove this device ($e); remove it from My devices',
          );
        }
      }
      await auth.signOut();
      expect(
        (await jar.loadForRequest(endpoint.origin))
            .where((c) => c.name == '__Host-atlas_session'),
        isEmpty,
      );
      stdout.writeln('PRODUCTION_CHECK_PASSED');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
