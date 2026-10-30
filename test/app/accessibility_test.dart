@Tags(['golden'])
library;

import 'package:atlas_mobile/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_assessment.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

/// Every main screen against Flutter's accessibility guidelines: tap
/// targets (iOS 44pt, Android 48dp) and every tappable thing has a label.
/// Arabic and English, light and dark. Text contrast is checked on the
/// colour tokens in test/design/contrast_test.dart (exact, unlike the
/// screenshot-sampled guideline, which misreads small text).
void main() {
  setUpAll(loadGoldenFonts);

  const course = FakeLearningRepository.courseId;
  final screens = <String, (SessionController Function(), String?)>{
    'picker': (AsNoAcademy.new, null),
    'sign-in': (AsSignedOut.new, null),
    'register': (AsSignedOut.new, '/academy/register'),
    'forgot': (AsSignedOut.new, '/academy/forgot'),
    'reset': (AsSignedOutLinks.new, '/academy/reset-password'),
    'home': (AsSignedIn.new, '/home'),
    'courses': (AsSignedIn.new, '/courses'),
    'tasks': (AsSignedIn.new, '/tasks'),
    'course': (AsSignedIn.new, '/course/$course'),
    'lesson': (AsSignedIn.new, '/course/$course/lesson/l2'),
    'catalog': (AsSignedIn.new, '/catalog'),
    'preview': (AsSignedIn.new, '/catalog/free-algebra'),
    'notifications': (AsSignedIn.new, '/notifications'),
    'announcements': (AsSignedIn.new, '/announcements'),
    'account': (AsSignedIn.new, '/account'),
    'profile': (AsSignedIn.new, '/account/profile'),
    'security': (AsSignedIn.new, '/account/security'),
    'notification-settings': (AsSignedIn.new, '/account/notifications'),
    'privacy': (AsSignedIn.new, '/account/privacy'),
    'devices': (AsSignedIn.new, '/account/devices'),
    'results': (AsSignedIn.new, '/account/results'),
    'certificates': (AsSignedIn.new, '/account/certificates'),
    'quiz': (AsSignedIn.new, '/course/$course/quiz/q1'),
    'assignment': (AsSignedIn.new, '/course/$course/assignment/a1'),
    'verify-email': (AsSignedInLinks.new, '/account/verify-email'),
    'about': (AsSignedIn.new, '/about'),
  };

  for (final (language, theme) in [
    ('ar', ThemeMode.light),
    ('en', ThemeMode.dark),
  ]) {
    for (final MapEntry(key: name, value: (session, path)) in screens.entries) {
      testWidgets('$name $language ${theme.name}', (t) async {
        final semantics = t.ensureSemantics();
        await pumpScreen(
          t,
          session: session,
          path: path,
          extra:
              path?.contains('reset') == true ||
                  path?.contains('verify') == true
              ? 'token'
              : null,
          language: language,
          theme: theme,
          assessments: FakeAssessmentRepository(),
        );
        await t.pump(const Duration(seconds: 2));
        await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }
  }

  // Largest common accessibility text size: nothing may overflow.
  for (final MapEntry(key: name, value: (session, path)) in screens.entries) {
    testWidgets('$name ar at 200% text', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpScreen(
        t,
        session: session,
        path: path,
        extra:
            path?.contains('reset') == true || path?.contains('verify') == true
            ? 'token'
            : null,
        assessments: FakeAssessmentRepository(),
      );
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });
  }
}
