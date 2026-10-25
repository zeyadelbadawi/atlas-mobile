@Tags(['golden'])
library;

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

class _SignedOutLinks extends _SignedOut {
  @override
  AuthRepository? get auth => FakeAuthRepository();
}

class _SignedInLinks extends _SignedIn {
  @override
  AuthRepository? get auth => FakeAuthRepository();
}

class _NoAcademy extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.noAcademy);
}

/// No platform channel in widget tests: links never arrive.
class _NoLinks extends DeepLinkController {
  @override
  void start() {}
}

class _PushNotAsked extends PushController {
  @override
  PushStatus build() => PushStatus.notAsked;
}

NotificationCatalog _notificationCatalog() => NotificationCatalog({
  for (final l in ['en', 'ar'])
    l: jsonDecode(
      File('assets/l10n/notifications_$l.json').readAsStringSync(),
    ) as Map<String, dynamic>,
});

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
      learningRepositoryProvider.overrideWithValue(FakeLearningRepository()),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      assessmentRepositoryProvider.overrideWithValue(
        assessments ?? FakeAssessmentRepository(),
      ),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
      notificationCatalogProvider.overrideWithValue(_notificationCatalog()),
      pushControllerProvider.overrideWith(_PushNotAsked.new),
      deepLinkProvider.overrideWith(_NoLinks.new),
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

  testWidgets('home_ar', (t) async {
    await _pump(t, session: _SignedIn.new, size: const Size(393, 1350));
    await _golden(t, 'home_ar');
  }, variant: ios);

  testWidgets('home_en_dark_android', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      size: const Size(412, 1350),
    );
    await _golden(t, 'home_en_dark_android');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('courses_ar', (t) async {
    await _pump(t, session: _SignedIn.new, path: '/courses');
    await _golden(t, 'courses_ar');
  }, variant: ios);

  testWidgets('course_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}',
      size: const Size(393, 1300),
    );
    await _golden(t, 'course_ar');
  }, variant: ios);

  testWidgets('lesson_text_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/lesson/l2',
      size: const Size(393, 1100),
    );
    await _golden(t, 'lesson_text_ar');
  }, variant: ios);

  testWidgets('devices_ar', (t) async {
    await _pump(t, session: _SignedIn.new, path: '/account/devices');
    await _golden(t, 'devices_ar');
  }, variant: ios);

  testWidgets('account_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account',
      size: const Size(393, 1700),
    );
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
  const course = FakeLearningRepository.courseId;

  testWidgets('quiz_intro_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/$course/quiz/l3',
      size: const Size(393, 1500),
    );
    await _golden(t, 'quiz_intro_ar');
  }, variant: ios);

  testWidgets('quiz_running_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.running),
    );
    await t.tap(find.text('٥'));
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'quiz_running_ar');
  }, variant: ios);

  testWidgets('quiz_results_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.results),
      size: const Size(393, 1900),
    );
    await _golden(t, 'quiz_results_ar');
  }, variant: ios);

  testWidgets('quiz_results_en_dark', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.results),
      size: const Size(393, 1900),
    );
    await _golden(t, 'quiz_results_en_dark');
  }, variant: ios);

  testWidgets('assignment_graded_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/course/$course/assignment/l6',
      size: const Size(393, 1500),
    );
    await _golden(t, 'assignment_graded_ar');
  }, variant: ios);

  testWidgets('results_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account/results',
      size: const Size(393, 1000),
    );
    await _golden(t, 'results_ar');
  }, variant: ios);

  testWidgets('certificates_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account/certificates',
      size: const Size(393, 1150),
    );
    await _golden(t, 'certificates_ar');
  }, variant: ios);
  testWidgets('notifications_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/notifications',
      size: const Size(393, 1250),
    );
    await _golden(t, 'notifications_ar');
  }, variant: ios);

  testWidgets('notifications_en_dark_android', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/notifications',
      size: const Size(393, 1250),
    );
    await _golden(t, 'notifications_en_dark_android');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('announcements_ar', (t) async {
    await _pump(t, session: _SignedIn.new, path: '/announcements');
    await _golden(t, 'announcements_ar');
  }, variant: ios);

  testWidgets('profile_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account/profile',
      size: const Size(393, 1100),
    );
    await _golden(t, 'profile_ar');
  }, variant: ios);

  testWidgets('security_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account/security',
      size: const Size(393, 1200),
    );
    await _golden(t, 'security_ar');
  }, variant: ios);

  testWidgets('privacy_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/account/privacy',
      size: const Size(393, 1000),
    );
    await _golden(t, 'privacy_ar');
  }, variant: ios);

  testWidgets('catalog_ar', (t) async {
    await _pump(t, session: _SignedIn.new, path: '/catalog');
    await _golden(t, 'catalog_ar');
  }, variant: ios);

  testWidgets('course_preview_ar', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      path: '/catalog/free-algebra',
      size: const Size(393, 1300),
    );
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'course_preview_ar');
  }, variant: ios);

  testWidgets('course_preview_en_dark_android', (t) async {
    await _pump(
      t,
      session: _SignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/catalog/free-physics',
      size: const Size(393, 1300),
    );
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'course_preview_en_dark_android');
  });

  testWidgets('reset_password_ar', (t) async {
    await _pump(
      t,
      session: _SignedOutLinks.new,
      path: '/academy/reset-password',
      extra: 'golden-token',
    );
    await _golden(t, 'reset_password_ar');
  }, variant: ios);

  testWidgets('verify_email_done_ar', (t) async {
    await _pump(
      t,
      session: _SignedInLinks.new,
      path: '/account/verify-email',
      extra: 'golden-token',
    );
    await _golden(t, 'verify_email_done_ar');
  }, variant: ios);
}
