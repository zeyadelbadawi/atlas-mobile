// Phase 0 spike: the session model against a REAL local Atlas backend.
//
// Runs only when ATLAS_SPIKE_ORIGIN is set, e.g.
//   ATLAS_SPIKE_ORIGIN=http://web-development-academy:3000 \
//   ATLAS_SPIKE_ACADEMY_ID=<id> flutter test test/integration
// The backend must be the disposable local stack
// (atlas-backend/scripts/e2e-local-stack.sh) — never production.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/api/secure_cookie_storage.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

const _ua = 'AtlasApp/0.1 (iPhone; iOS 18.0) Dart';

void main() {
  final origin = Platform.environment['ATLAS_SPIKE_ORIGIN'];
  final academyId = Platform.environment['ATLAS_SPIKE_ACADEMY_ID'];
  final skip = origin == null || academyId == null
      ? 'set ATLAS_SPIKE_ORIGIN and ATLAS_SPIKE_ACADEMY_ID'
      : null;
  if (origin != null &&
      !Uri.parse(origin).host.contains(RegExp(r'^[a-z0-9-]+$'))) {
    throw StateError('spike runs against a local single-label host only');
  }

  late AcademyEndpoint endpoint;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'spike-$stamp@example.test';
  const password = 'Spike-Passw0rd!x';
  // A unique, valid Egyptian mobile per run (the backend enforces one
  // account per number).
  final phone = '010${(stamp % 100000000).toString().padLeft(8, '0')}';
  final storage = MemoryCookieStorage();

  AtlasApiClient newClient() => AtlasApiClient(
    endpoint: endpoint,
    cookieJar: PersistCookieJar(storage: storage),
    userAgent: _ua,
  );

  setUpAll(() {
    if (skip == null) endpoint = AcademyEndpoint.parse(origin!);
  });

  test('register, sign in, refresh, restore after restart, sign out', () async {
    var client = newClient();
    var auth = AuthRepository(client, academyId: academyId!);

    expect(
      await auth.register(
        name: 'Spike Learner',
        email: email,
        password: password,
        phoneNumber: phone,
        phoneCountry: 'EG',
      ),
      'new',
    );

    final outcome = await auth.signIn(email: email, password: password);
    expect(
      outcome,
      isA<SignedIn>(),
      reason: 'OTP is off on the default local stack',
    );
    expect(client.accessToken, isNotNull);

    final cookies = await client.cookieJar.loadForRequest(endpoint.origin);
    final names = cookies.map((c) => c.name).toSet();
    expect(names, containsAll(['atlas_session', 'atlas_device']));
    final firstSession = cookies
        .firstWhere((c) => c.name == 'atlas_session')
        .value;

    final me = await client.get<Map<String, dynamic>>('users/me');
    expect(me['email'], email);

    // Refresh rotates the cookie and returns the user.
    final refreshed = await client.refreshSession();
    expect(refreshed['user'], isA<Map<String, dynamic>>());
    final rotated = (await client.cookieJar.loadForRequest(endpoint.origin))
        .firstWhere((c) => c.name == 'atlas_session')
        .value;
    expect(rotated, isNot(firstSession));

    // "Restart": a brand-new client on the same persisted jar.
    client = newClient();
    auth = AuthRepository(client, academyId: academyId);
    expect(client.accessToken, isNull);
    final restored = await auth.restore();
    expect(restored?['email'], email);

    // An expired access token is refreshed transparently, once.
    client.setAccessToken('expired.token.value');
    final again = await client.get<Map<String, dynamic>>('users/me');
    expect(again['email'], email);

    await auth.signOut();
    expect(
      await client.cookieJar.loadForRequest(endpoint.origin),
      isNot(contains(predicate<Cookie>((c) => c.name == 'atlas_session'))),
    );
    await expectLater(
      client.refreshSession(),
      throwsA(isA<AtlasApiException>().having((e) => e.status, 'status', 401)),
    );
  }, skip: skip);

  test(
    'ten concurrent refreshes make one request and keep the session',
    () async {
      final client = newClient();
      final auth = AuthRepository(client, academyId: academyId!);
      await auth.signIn(email: email, password: password);

      final results = await Future.wait(
        List.generate(10, (_) => client.refreshSession()),
      );
      expect(results.map((r) => r['accessToken']).toSet(), hasLength(1));

      // The session is still alive: a further refresh works.
      expect((await client.refreshSession())['accessToken'], isA<String>());
      await auth.signOut();
    },
    skip: skip,
  );

  test(
    'a refresh without Origin is refused (why the client sends it)',
    () async {
      final client = newClient();
      final auth = AuthRepository(client, academyId: academyId!);
      await auth.signIn(email: email, password: password);
      client.dio.interceptors.removeWhere(
        (i) => i.runtimeType.toString() == '_AuthInterceptor',
      );
      await expectLater(
        () => client.post<Map<String, dynamic>>('auth/refresh'),
        throwsA(
          isA<AtlasApiException>().having(
            (e) => e.messageKey,
            'messageKey',
            'errors.auth.crossOriginSession',
          ),
        ),
      );
    },
    skip: skip,
  );
}
