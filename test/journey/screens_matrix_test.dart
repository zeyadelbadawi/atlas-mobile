// Learner-journey QA: every screen of the app in four set-ups, a picture
// of each for review, and failure on any error, overflow or exception.
//
//   flutter test --tags journey test/journey
//
// Writes build/journey/<setup>/<screen>.png.
@Tags(['journey'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fake_assessment.dart';
import '../app/fake_catalog.dart';
import '../app/fake_learning.dart';
import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

const _c = FakeLearningRepository.courseId;

/// name → (session, path, extra).
final screens = <String, (SessionController Function(), String?, Object?)>{
  '01_picker': (AsNoAcademy.new, null, null),
  '02_sign_in': (AsSignedOut.new, null, null),
  '03_register': (AsSignedOut.new, '/academy/register', null),
  '04_forgot': (AsSignedOut.new, '/academy/forgot', null),
  '05_reset': (AsSignedOutLinks.new, '/academy/reset-password', 'token'),
  '10_home': (AsSignedIn.new, '/home', null),
  '11_courses': (AsSignedIn.new, '/courses', null),
  '12_tasks': (AsSignedIn.new, '/tasks', null),
  '13_notifications': (AsSignedIn.new, '/notifications', null),
  '14_account': (AsSignedIn.new, '/account', null),
  '20_course': (AsSignedIn.new, '/course/$_c', null),
  '21_lesson_text': (AsSignedIn.new, '/course/$_c/lesson/l2', null),
  '22_live_next': (AsSignedIn.new, '/course/$_c/live/ls-next', null),
  '23_live_now': (AsSignedIn.new, '/course/$_c/live/ls-now', null),
  '24_live_done': (AsSignedIn.new, '/course/$_c/live/ls-done', null),
  '25_live_cancelled': (AsSignedIn.new, '/course/$_c/live/ls-off', null),
  '30_quiz_intro': (AsSignedIn.new, '/course/$_c/quiz/l3', null),
  '31_assignment': (AsSignedIn.new, '/course/$_c/assignment/l6', null),
  '40_catalog': (AsSignedIn.new, '/catalog', null),
  '41_preview': (AsSignedIn.new, '/catalog/free-algebra', null),
  '42_reviews': (AsSignedIn.new, '/catalog/free-algebra/reviews', null),
  '50_announcements': (AsSignedIn.new, '/announcements', null),
  '51_announcement': (AsSignedIn.new, '/announcements/a1', null),
  '60_profile': (AsSignedIn.new, '/account/profile', null),
  '61_security': (AsSignedIn.new, '/account/security', null),
  '62_notif_settings': (AsSignedIn.new, '/account/notifications', null),
  '63_privacy': (AsSignedIn.new, '/account/privacy', null),
  '64_devices': (AsSignedIn.new, '/account/devices', null),
  '65_results': (AsSignedIn.new, '/account/results', null),
  '66_certificates': (AsSignedIn.new, '/account/certificates', null),
  '67_notes': (AsSignedIn.new, '/account/notes', null),
  '68_verify_email': (AsSignedInLinks.new, '/account/verify-email', 'token'),
  '70_legal': (AsSignedIn.new, '/legal', null),
  '71_terms': (AsSignedIn.new, '/legal/terms', null),
  '72_about': (AsSignedIn.new, '/about', null),
};

/// (name, language, theme, size, text scale, platform).
const setups = [
  ('a_phone_ar_light', 'ar', ThemeMode.light, Size(393, 852), 1.0, false),
  ('b_phone_en_dark', 'en', ThemeMode.dark, Size(393, 852), 1.0, true),
  ('c_small_ar_large', 'ar', ThemeMode.light, Size(320, 640), 1.3, false),
  ('d_ipad_ar', 'ar', ThemeMode.light, Size(1032, 1376), 1.0, true),
];

Future<void> _capture(WidgetTester t, String path) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump(const Duration(milliseconds: 300));
  }
  final element = t.element(find.byType(AtlasApp));
  await t.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void _quietPhone(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  const events = EventChannel('atlas/screen_capture/events');
  m.setMockStreamHandler(events, MockStreamHandler.inline(onListen: (_, _) {}));
  addTearDown(() => m.setMockStreamHandler(events, null));
}

void main() {
  setUpAll(loadGoldenFonts);
  for (final (setup, language, theme, size, scale, ios) in setups) {
    for (final MapEntry(key: name, value: (session, path, extra))
        in screens.entries) {
      testWidgets(
        '$setup $name',
        (t) async {
          _quietPhone(t);
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpScreen(
            t,
            session: session,
            path: path,
            extra: extra,
            language: language,
            theme: theme,
            size: size,
            assessments: FakeAssessmentRepository(),
            catalog: RatedCatalog(),
          );
          await t.pump(const Duration(seconds: 1));
          await _capture(t, 'build/journey/$setup/$name.png');
          // Scrolled to the end too: what is below the fold.
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            final state = t.state<ScrollableState>(scrollables.first);
            final max = state.position.maxScrollExtent;
            if (max > 50 && state.position.axis == Axis.vertical) {
              state.position.jumpTo(max);
              await t.pump();
              await _capture(t, 'build/journey/$setup/${name}_end.png');
            }
          }
        },
        variant: TargetPlatformVariant.only(
          ios ? TargetPlatform.iOS : TargetPlatform.android,
        ),
      );
    }
  }
}
