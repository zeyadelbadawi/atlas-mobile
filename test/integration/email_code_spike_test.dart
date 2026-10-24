// Phase 0 spike: the emailed sign-in code and the trusted-device cookie,
// against a local backend started with FLAG_AUTH_EMAIL_OTP_MODE_ACADEMY=new_device.
//
//   ATLAS_SPIKE_ORIGIN=http://web-development-academy:3000 \
//   ATLAS_SPIKE_ACADEMY_ID=<id> ATLAS_SPIKE_OTP_ENV=/tmp/atlas-e2e-stack/backend.env \
//   flutter test test/integration/email_code_spike_test.dart
//
// The code is set on the LOCAL database by tool/local_stack/force_otp_code.mjs.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/api/secure_cookie_storage.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  final env = Platform.environment;
  final origin = env['ATLAS_SPIKE_ORIGIN'];
  final academyId = env['ATLAS_SPIKE_ACADEMY_ID'];
  final otpEnv = env['ATLAS_SPIKE_OTP_ENV'];
  final skip = origin == null || academyId == null || otpEnv == null
      ? 'set ATLAS_SPIKE_ORIGIN, ATLAS_SPIKE_ACADEMY_ID and ATLAS_SPIKE_OTP_ENV'
      : null;

  test('new device gets a code; a remembered device does not', () async {
    final endpoint = AcademyEndpoint.parse(origin!);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'otp-$stamp@example.test';
    const password = 'Spike-Passw0rd!x';
    final storage = MemoryCookieStorage();
    AtlasApiClient client() => AtlasApiClient(
      endpoint: endpoint,
      cookieJar: PersistCookieJar(storage: storage),
      userAgent: 'AtlasApp/0.1 (Android 15) Dart',
    );

    final auth = AuthRepository(client(), academyId: academyId!);
    await auth.register(
      name: 'Code Learner',
      email: email,
      password: password,
      phoneNumber: '011${(stamp % 100000000).toString().padLeft(8, '0')}',
      phoneCountry: 'EG',
    );

    final first = await auth.signIn(email: email, password: password);
    expect(first, isA<EmailCodeRequired>());
    final challenge = first as EmailCodeRequired;
    expect(challenge.maskedEmail, contains('•'));
    expect(
      auth.client.accessToken,
      isNull,
      reason: 'a challenge carries no token',
    );

    final helper = await Process.run('node', [
      'tool/local_stack/force_otp_code.mjs',
      otpEnv!,
      email,
      '246810',
    ]);
    expect(helper.exitCode, 0, reason: '${helper.stdout}${helper.stderr}');

    final verified = await auth.verifyEmailCode(
      challengeId: challenge.challengeId,
      code: '246810',
      rememberDevice: true,
    );
    expect(verified, isA<SignedIn>());
    final names = (await auth.client.cookieJar.loadForRequest(endpoint.origin))
        .map((c) => c.name)
        .toSet();
    expect(names, contains('atlas_trust'));

    // Same phone (same jar), new app process: no code this time.
    final again = AuthRepository(client(), academyId: academyId);
    expect(
      await again.signIn(email: email, password: password),
      isA<SignedIn>(),
    );
    await again.signOut();
  }, skip: skip);
}
