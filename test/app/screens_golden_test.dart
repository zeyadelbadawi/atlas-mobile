@Tags(['golden'])
library;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_assessment.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

Future<void> _golden(WidgetTester tester, String name) =>
    expectGolden(tester, find.byType(AtlasApp), 'goldens/$name.png');

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('picker_ar', (t) async {
    await pumpScreen(t, session: AsNoAcademy.new);
    await _golden(t, 'picker_ar');
  }, variant: ios);

  testWidgets('signin_ar', (t) async {
    await pumpScreen(t, session: AsSignedOut.new, size: const Size(393, 1100));
    await _golden(t, 'signin_ar');
  }, variant: ios);

  testWidgets('signin_en_dark', (t) async {
    await pumpScreen(
      t,
      session: AsSignedOut.new,
      language: 'en',
      theme: ThemeMode.dark,
      size: const Size(393, 1100),
    );
    await _golden(t, 'signin_en_dark');
  }, variant: ios);

  testWidgets('register_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedOut.new,
      path: '/academy/register',
      size: const Size(393, 1250),
    );
    await _golden(t, 'register_ar');
  }, variant: ios);

  testWidgets('code_ar', (t) async {
    // The test's fake clock: the countdown reads the same every run.
    final now = clock.now();
    await pumpScreen(
      t,
      session: AsSignedOut.new,
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
    await pumpScreen(t, session: AsSignedIn.new, size: const Size(393, 1350));
    await _golden(t, 'home_ar');
  }, variant: ios);

  testWidgets('home_en_dark_android', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      size: const Size(412, 1350),
    );
    await _golden(t, 'home_en_dark_android');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('courses_ar', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/courses');
    await _golden(t, 'courses_ar');
  }, variant: ios);

  testWidgets('course_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}',
      size: const Size(393, 1300),
    );
    await _golden(t, 'course_ar');
  }, variant: ios);

  testWidgets('lesson_text_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/lesson/l2',
      size: const Size(393, 1100),
    );
    await _golden(t, 'lesson_text_ar');
  }, variant: ios);

  testWidgets('devices_ar', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/account/devices');
    await _golden(t, 'devices_ar');
  }, variant: ios);

  testWidgets('account_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account',
      size: const Size(393, 1700),
    );
    await _golden(t, 'account_ar');
  }, variant: ios);

  testWidgets('about_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/about',
      size: const Size(393, 1000),
    );
    await _golden(t, 'about_ar');
  }, variant: ios);

  testWidgets('signin_ar_ipad', (t) async {
    await pumpScreen(t, session: AsSignedOut.new, size: const Size(820, 1180));
    await _golden(t, 'signin_ar_ipad');
  }, variant: ios);
  const course = FakeLearningRepository.courseId;

  testWidgets('quiz_intro_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/$course/quiz/l3',
      size: const Size(393, 1500),
    );
    await _golden(t, 'quiz_intro_ar');
  }, variant: ios);

  testWidgets('quiz_running_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.running),
    );
    await t.tap(find.text('٥'));
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'quiz_running_ar');
  }, variant: ios);

  testWidgets('quiz_results_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.results),
      size: const Size(393, 1900),
    );
    await _golden(t, 'quiz_results_ar');
  }, variant: ios);

  testWidgets('quiz_results_en_dark', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/course/$course/quiz/l3',
      assessments: FakeAssessmentRepository(stage: QuizStage.results),
      size: const Size(393, 1900),
    );
    await _golden(t, 'quiz_results_en_dark');
  }, variant: ios);

  testWidgets('assignment_graded_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/$course/assignment/l6',
      size: const Size(393, 1500),
    );
    await _golden(t, 'assignment_graded_ar');
  }, variant: ios);

  testWidgets('results_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/results',
      size: const Size(393, 1000),
    );
    await _golden(t, 'results_ar');
  }, variant: ios);

  testWidgets('certificates_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/certificates',
      size: const Size(393, 1150),
    );
    await _golden(t, 'certificates_ar');
  }, variant: ios);
  testWidgets('notifications_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/notifications',
      size: const Size(393, 1250),
    );
    await _golden(t, 'notifications_ar');
  }, variant: ios);

  testWidgets('notifications_en_dark_android', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/notifications',
      size: const Size(393, 1250),
    );
    await _golden(t, 'notifications_en_dark_android');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('announcements_ar', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/announcements');
    await _golden(t, 'announcements_ar');
  }, variant: ios);

  testWidgets('profile_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/profile',
      size: const Size(393, 1100),
    );
    await _golden(t, 'profile_ar');
  }, variant: ios);

  testWidgets('security_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/security',
      size: const Size(393, 1200),
    );
    await _golden(t, 'security_ar');
  }, variant: ios);

  testWidgets('privacy_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/privacy',
      size: const Size(393, 1000),
    );
    await _golden(t, 'privacy_ar');
  }, variant: ios);

  testWidgets('catalog_ar', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/catalog');
    await _golden(t, 'catalog_ar');
  }, variant: ios);

  testWidgets('course_preview_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/catalog/free-algebra',
      size: const Size(393, 1300),
    );
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'course_preview_ar');
  }, variant: ios);

  testWidgets('course_preview_en_dark_android', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      language: 'en',
      theme: ThemeMode.dark,
      path: '/catalog/free-physics',
      size: const Size(393, 1300),
    );
    await t.pump(const Duration(milliseconds: 300));
    await _golden(t, 'course_preview_en_dark_android');
  });

  testWidgets('reset_password_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedOutLinks.new,
      path: '/academy/reset-password',
      extra: 'golden-token',
    );
    await _golden(t, 'reset_password_ar');
  }, variant: ios);

  testWidgets('verify_email_done_ar', (t) async {
    await pumpScreen(
      t,
      session: AsSignedInLinks.new,
      path: '/account/verify-email',
      extra: 'golden-token',
    );
    await _golden(t, 'verify_email_done_ar');
  }, variant: ios);

  for (final (group, name) in [
    (null, 'tasks_ar'),
    ('awaiting', 'tasks_awaiting_ar'),
    ('graded', 'tasks_graded_ar'),
  ]) {
    testWidgets(name, (t) async {
      await pumpScreen(
        t,
        session: AsSignedIn.new,
        path: '/tasks',
        size: const Size(393, 1100),
        assessments: FakeAssessmentRepository(),
      );
      if (group != null) {
        await t.tap(
          find.textContaining(group == 'awaiting' ? 'للتصحيح' : 'مصحّحة'),
        );
        await t.pump(const Duration(milliseconds: 400));
      }
      await _golden(t, name);
    }, variant: ios);
  }

  testWidgets('picker_en_dark', (t) async {
    await pumpScreen(
      t,
      session: AsNoAcademy.new,
      language: 'en',
      theme: ThemeMode.dark,
    );
    await _golden(t, 'picker_en_dark');
  }, variant: ios);

  testWidgets('picker_ar_ipad', (t) async {
    await pumpScreen(t, session: AsNoAcademy.new, size: const Size(1032, 1376));
    await _golden(t, 'picker_ar_ipad');
  }, variant: ios);

  testWidgets('home_ar_scrolled', (t) async {
    await pumpScreen(t, session: AsSignedIn.new, path: '/home');
    await t.drag(find.byType(ListView).first, const Offset(0, -320));
    await t.pump(const Duration(milliseconds: 400));
    await _golden(t, 'home_ar_scrolled');
  }, variant: ios);

  testWidgets('home_ar_ipad', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/home',
      size: const Size(1032, 1376),
    );
    await _golden(t, 'home_ar_ipad');
  }, variant: ios);
}
