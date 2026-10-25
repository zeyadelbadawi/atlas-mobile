// Shared setup for screen tests (goldens, accessibility): the whole app
// with fake repositories, a chosen session, language, theme and size.
import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/deep_links.dart';
import 'package:atlas_mobile/app/learning_providers.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/push.dart';
import 'package:atlas_mobile/app/router.dart';
import 'package:atlas_mobile/core/notifications/notification_catalog.dart';
import 'package:atlas_mobile/features/account/account_settings_screens.dart';
import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/errors/error_catalog.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/golden_harness.dart';
import 'fake_assessment.dart';
import 'fake_catalog.dart';
import 'fake_notifications.dart';
import 'fake_learning.dart';

const ziadd = Academy(
  id: '7857eec7-d94f-4c83-b65f-99652924ae1e',
  name: 'Ziadd',
  host: 'ziadd.atlass.dpdns.org',
  slug: 'ziadd',
  primaryColor: '40 95% 54%',
);

class AsSignedIn extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    academy: ziadd,
    user: {'name': 'زياد البدوي', 'email': 'zeyad@example.com'},
  );
}

class AsSignedOut extends SessionController {
  @override
  SessionState build() =>
      const SessionState(status: SessionStatus.signedOut, academy: ziadd);
}

class AsSignedOutLinks extends AsSignedOut {
  @override
  AuthRepository? get auth => FakeAuthRepository();
}

class AsSignedInLinks extends AsSignedIn {
  @override
  AuthRepository? get auth => FakeAuthRepository();
}

class AsNoAcademy extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.noAcademy);
}

/// No platform channel in widget tests: links never arrive.
class NoLinks extends DeepLinkController {
  @override
  void start() {}
}

class PushNotAsked extends PushController {
  @override
  PushStatus build() => PushStatus.notAsked;
}

NotificationCatalog notificationCatalog() => NotificationCatalog({
  for (final l in ['en', 'ar'])
    l: jsonDecode(
      File('assets/l10n/notifications_$l.json').readAsStringSync(),
    ) as Map<String, dynamic>,
});

ErrorCatalog errorCatalog() => ErrorCatalog({
  for (final l in ['en', 'ar'])
    l: jsonDecode(
      File('assets/l10n/errors_$l.json').readAsStringSync(),
    ) as Map<String, dynamic>,
});

Future<ProviderContainer> pumpScreen(
  WidgetTester tester, {
  required SessionController Function() session,
  String language = 'ar',
  ThemeMode theme = ThemeMode.light,
  String? path,
  Object? extra,
  Size size = const Size(393, 852),
  FakeAssessmentRepository? assessments,
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
      errorCatalogProvider.overrideWithValue(errorCatalog()),
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
      learningRepositoryProvider.overrideWithValue(FakeLearningRepository()),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      assessmentRepositoryProvider.overrideWithValue(
        assessments ?? FakeAssessmentRepository(),
      ),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
      notificationCatalogProvider.overrideWithValue(notificationCatalog()),
      pushControllerProvider.overrideWith(PushNotAsked.new),
      deepLinkProvider.overrideWith(NoLinks.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AtlasApp()),
  );
  await tester.pump();
  if (path != null) {
    final router = container.read(routerProvider);
    const tabs = {'/home', '/courses', '/notifications', '/account'};
    tabs.contains(path) ? router.go(path) : router.push(path, extra: extra);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
