// Shared setup for screen tests (goldens, accessibility): the whole app
// with fake repositories, a chosen session, language, theme and size.
import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/deep_links.dart';
import 'package:atlas_mobile/app/learning_providers.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/app/reminders.dart';
import 'package:atlas_mobile/core/platform/calendar.dart';
import 'package:atlas_mobile/core/reminders/local_reminders.dart';
import 'package:atlas_mobile/core/academy/academy_directory.dart';
import 'package:atlas_mobile/app/push.dart';
import 'package:atlas_mobile/app/router.dart';
import 'package:atlas_mobile/core/notifications/notification_catalog.dart';
import 'package:atlas_mobile/features/account/account_settings_screens.dart';
import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/errors/error_catalog.dart';
import 'package:atlas_mobile/core/learning/assessment_repository.dart';
import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:atlas_mobile/core/notifications/notifications_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/golden_harness.dart';
import 'fake_reminders.dart';
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
    user: {'id': 'u1', 'name': 'زياد البدوي', 'email': 'zeyad@example.com'},
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
  AssessmentRepository? assessments,
  LearningRepository? learning,
  CatalogRepository? catalog,
  NotificationsRepository? notifications,
  MobileConfig config = const MobileConfig(signInWithApple: true),
  AcademyDirectory? directory,
  Map<String, Object> prefs = const {},
  List<Academy>? recent,
  LocalReminders? reminders,
  AddToCalendar? calendar,
}) async {
  SharedPreferences.setMockInitialValues({
    ...prefs,
    'settings.language': language,
    'settings.theme': theme.name,
    'academy.recent': recent != null
        ? [for (final a in recent) jsonEncode(a.toJson())]
        : [
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
  final store = await SharedPreferences.getInstance();
  await setDevice(tester, size);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(store),
      errorCatalogProvider.overrideWithValue(errorCatalog()),
      appVersionProvider.overrideWithValue((version: '1.0.0', build: '1')),
      cookieJarProvider.overrideWithValue(CookieJar()),
      bodyFontProvider.overrideWithValue((
        family: testBodyFamily,
        fallback: testBodyFallback,
      )),
      mobileConfigProvider.overrideWith((ref) async => config),
      sessionProvider.overrideWith(session),
      if (directory != null)
        academyDirectoryProvider.overrideWithValue(directory),
      learningRepositoryProvider.overrideWithValue(
        learning ?? FakeLearningRepository(),
      ),
      catalogRepositoryProvider.overrideWithValue(
        catalog ?? FakeCatalogRepository(),
      ),
      assessmentRepositoryProvider.overrideWithValue(
        assessments ?? FakeAssessmentRepository(),
      ),
      notificationsRepositoryProvider.overrideWithValue(
        notifications ?? FakeNotificationsRepository(),
      ),
      accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
      notificationCatalogProvider.overrideWithValue(notificationCatalog()),
      pushControllerProvider.overrideWith(PushNotAsked.new),
      deepLinkProvider.overrideWith(NoLinks.new),
      splashEnabledProvider.overrideWithValue(false),
      localRemindersProvider.overrideWithValue(reminders ?? FakeReminders()),
      addToCalendarProvider.overrideWithValue(calendar ?? (_) async => true),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AtlasApp()),
  );
  await tester.pump();
  if (path != null) {
    final router = container.read(routerProvider);
    const tabs = {'/home', '/courses', '/tasks', '/notifications', '/account'};
    tabs.contains(path) ? router.go(path) : router.push(path, extra: extra);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  // Let content that arrived in that pump finish fading in (AsyncBody) and
  // rising into place (Entrance, up to ~0.8 s with its stagger).
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 800));
  return container;
}

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
