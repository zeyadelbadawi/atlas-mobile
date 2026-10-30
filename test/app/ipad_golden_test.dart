@Tags(['golden'])
library;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_assessment.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

/// iPad (mini, 11", 13"; portrait and landscape) and an Android tablet:
/// the sidebar and the side-by-side list and item (master/detail).
void main() {
  setUpAll(loadGoldenFonts);

  const course = FakeLearningRepository.courseId;
  const devices = {
    'mini_portrait': Size(744, 1133),
    'ipad11_landscape': Size(1194, 834),
    'ipad13_portrait': Size(1032, 1376),
    'ipad13_landscape': Size(1376, 1032),
  };
  const screens = {
    'home': '/home',
    'course': '/course/$course',
    'lesson': '/course/$course/lesson/l2',
    'account': '/account',
    'announcements': '/announcements',
  };

  for (final MapEntry(key: device, value: size) in devices.entries) {
    for (final MapEntry(key: screen, value: path) in screens.entries) {
      testWidgets('${screen}_$device', (t) async {
        await pumpScreen(
          t,
          session: AsSignedIn.new,
          path: path,
          size: size,
          assessments: FakeAssessmentRepository(),
        );
        // The open item beside a list loads after the list.
        await t.pump(const Duration(milliseconds: 500));
        await expectLater(
          find.byType(AtlasApp),
          matchesGoldenFile('goldens/ipad/${screen}_$device.png'),
        );
      }, variant: ios);
    }
  }

  // Android tablet, landscape: the NavigationRail.
  testWidgets('home_android_tablet', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/home',
      size: const Size(1280, 800),
    );
    await expectLater(
      find.byType(AtlasApp),
      matchesGoldenFile('goldens/ipad/home_android_tablet.png'),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
