// Phase 6 against the LOCAL stack: the emailed links the app now opens
// itself. A verification link completes for its own account (and a made-up
// token is refused); a reset link is checked, sets the new password once,
// ends the old session, and cannot be used twice. Env as local_stack.dart.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

void main() {
  final skip = Platform.environment['ATLAS_SPIKE_ORIGIN'] == null
      ? 'needs the local stack'
      : null;

  test(
    'verify-email link',
    () async {
      final me = await newLocalLearner('p6v');
      final auth = AuthRepository(me.client, academyId: localAcademyId);
      await expectLater(
        auth.verifyEmail('made-up-token-${me.userId}'),
        throwsA(
          isA<AtlasApiException>().having(
            (e) => e.messageKey,
            'key',
            'errors.auth.invalidVerificationToken',
          ),
        ),
      );
      final token = 'p6verify${DateTime.now().microsecondsSinceEpoch}';
      await forceLinkToken(me.email, 'verify', token);
      await auth.verifyEmail(token);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'reset-password link',
    () async {
      final me = await newLocalLearner('p6r');
      final guest = AtlasApiClient(
        endpoint: localAcademy,
        cookieJar: CookieJar(),
        userAgent: 'AtlasApp/0.6 (Android)',
      );
      final auth = AuthRepository(guest, academyId: localAcademyId);
      await auth.requestPasswordReset(me.email);
      final token = 'p6reset${DateTime.now().microsecondsSinceEpoch}';
      await forceLinkToken(me.email, 'reset', token);

      expect(await auth.validateResetToken('not-$token'), isFalse);
      expect(await auth.validateResetToken(token), isTrue);
      const next = 'Fresh-Passw0rd!z';
      await auth.confirmPasswordReset(token, next);
      expect(await auth.validateResetToken(token), isFalse);
      await expectLater(
        auth.confirmPasswordReset(token, next),
        throwsA(
          isA<AtlasApiException>().having(
            (e) => e.messageKey,
            'key',
            'errors.auth.invalidResetToken',
          ),
        ),
      );

      // Every session ended, the app's included.
      await expectLater(
        me.client.get<dynamic>('users/me'),
        throwsA(isA<AtlasApiException>()),
      );
      // The new password works; the old one no longer does.
      final outcome = await auth.signIn(email: me.email, password: next);
      expect(outcome, anyOf(isA<SignedIn>(), isA<EmailCodeRequired>()));
      await expectLater(
        auth.signIn(email: me.email, password: me.password),
        throwsA(isA<AtlasApiException>()),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
