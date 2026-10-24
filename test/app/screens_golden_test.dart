@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/router.dart';
import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/errors/error_catalog.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/golden_harness.dart';

const ziadd = Academy(
  id: '7857eec7-d94f-4c83-b65f-99652924ae1e',
  name: 'Ziadd',
  host: 'ziadd.atlass.dpdns.org',
  slug: 'ziadd',
  primaryColor: '40 95% 54%',
);

class _SignedIn extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    academy: ziadd,
    user: {'name': 'زياد البدوي', 'email': 'zeyad@example.com'},
  );
}

class _SignedOut extends SessionController {
  @override
  SessionState build() =>
      const SessionState(status: SessionStatus.signedOut, academy: ziadd);
}

class _NoAcademy extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.noAcademy);
}

ErrorCatalog _errors() => ErrorCatalog({
  for (final l in ['en', 'ar'])
    l: jsonDecode(
      File('assets/l10n/errors_$l.json').readAsStringSync(),
    ) as Map<String, dynamic>,
});

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required SessionController Function() session,
  String language = 'ar',
  ThemeMode theme = ThemeMode.light,
  String? path,
  Object? extra,
  Size size = const Size(393, 852),
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.language': language,
    'settings.theme': theme.name,
    'academy.recent': [
      jsonEncode(ziadd.toJson()),
      jsonEncode(
        const Academy(
          id: 'm',
          name: 'Manara',
          host: 'manara.atlass.dpdns.org',
          primaryColor: '222 72% 46%',
        ).toJson(),
      ),
    ],
  });
  final prefs = await SharedPreferences.getInstance();
  await setDevice(tester, size);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      errorCatalogProvider.overrideWithValue(_errors()),
      appVersionProvider.overrideWithValue((version: '1.0.0', build: '1')),
      cookieJarProvider.overrideWithValue(CookieJar()),
      bodyFontProvider.overrideWithValue((
        family: testBodyFamily,
        fallback: testBodyFallback,
      )),
      mobileConfigProvider.overrideWith(
        (ref) async => const MobileConfig(signInWithApple: true),
      ),
      sessionProvider.overrideWith(session),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AtlasApp()),
  );
  await tester.pump();
  if (path != null) {
    container.read(routerProvider).push(path, extra: extra);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Future<void> _golden(WidgetTester tester, String name) =>
    expectLater(find.byType(AtlasApp), matchesGoldenFile('goldens/$name.png'));

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('picker_ar', (t) async {
    await _pump(t, session: _NoAcademy.new);
    await _golden(t, 'picker_ar');
  }, variant: ios);

  testWidgets('signin_ar', (t) async {
    await _pump(t, session: _SignedOut.new, size: const Size(393, 1100));
    await _golden(t, 'signin_ar');
  }, variant: ios);

  testWidgets('signin_en_dark', (t) async {
    await _pump(
      t,
      session: _SignedOut.new,
      language: 'en',
      theme: ThemeMode.dark,
      size: const Size(393, 1100),
    );
    await _golden(t, 'signin_en_dark');
  }, variant: ios);

  testWidgets('register_ar', (t) async {
    await _pump(
      t,
      session: _SignedOut.new,
      path: '/academy/register',
      size: const Size(393, 1250),
    );
    await _golden(t, 'register_ar');
  }, variant: ios);

  testWidgets('code_ar', (t) async {
    final now = DateTime.now();
    await _pump(
      t,
      session: _SignedOut.new,
      path: '/academy/code',
      extra: EmailCodeRequired(
        challengeId: 'c',
        maskedEmail: 'z•••@msa.edu.eg',
        expiresAt: now.add(const Duration(minutes: 10)),
        resendAvailableAt: now.add(const Duration(seconds: 45)),
        resendsRemaining: 3,
      ),
    );
    await _golden(t, 'code_ar');
  }, variant: ios);

  testWidgets('account_ar', (t) async {
    await _pump(t, session: _SignedIn.new, size: const Size(393, 1100));
    await _golden(t, 'account_ar');
  }, variant: ios);

  testWidgets('about_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/about',
      size: const Size(393, 1000),
    );
    await _golden(t, 'about_ar');
  }, variant: ios);

  testWidgets('signin_ar_ipad', (t) async {
    await _pump(t, session: _SignedOut.new, size: const Size(820, 1180));
    await _golden(t, 'signin_ar_ipad');
  }, variant: ios);
}
