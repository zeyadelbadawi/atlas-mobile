@Tags(['store'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fake_assessment.dart';
import '../app/fake_learning.dart';
import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

/// App Store and Google Play screenshots, rendered from the real screens
/// with demo data, in Arabic and English:
///
///   STORE_SHOTS=1 flutter test --tags store test/store
///
/// Writes PNGs to `build/store_screenshots/<device>/<lang>/` (not committed).
/// iPhone 6.9" 1320×2868 and iPad 13" 2064×2752, the sizes App Store
/// Connect asks for; the iPhone set also serves Google Play.
final _enabled = Platform.environment['STORE_SHOTS'] == '1';

const _course = FakeLearningRepository.courseId;
final _shots = <(String, SessionController Function(), String?, QuizStage?)>[
  ('1_home', AsSignedIn.new, '/home', null),
  ('2_course', AsSignedIn.new, '/course/$_course', null),
  ('3_lesson', AsSignedIn.new, '/course/$_course/lesson/l2', null),
  (
    '4_quiz_result',
    AsSignedIn.new,
    '/course/$_course/quiz/l3',
    QuizStage.results,
  ),
  ('5_tasks', AsSignedIn.new, '/tasks', null),
  ('6_certificates', AsSignedIn.new, '/account/certificates', null),
  ('7_picker', AsNoAcademy.new, null, null),
];

const _devices = <(String, Size, double)>[
  ('iphone_6.9', Size(440, 956), 3), // 1320 × 2868
  ('ipad_13', Size(1032, 1376), 2), // 2064 × 2752
];

Future<void> _save(WidgetTester t, String path) async {
  debugDisableShadows = false;
  void dirty(RenderObject o) {
    o.markNeedsPaint();
    o.visitChildren(dirty);
  }

  for (final v in t.binding.renderViews) {
    dirty(v);
  }
  await t.pump();
  final element = t.element(find.byType(AtlasApp));
  await t.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

void main() {
  setUpAll(loadGoldenFonts);

  for (final (device, size, ratio) in _devices) {
    for (final lang in ['ar', 'en']) {
      for (final (name, session, path, stage) in _shots) {
        testWidgets(
          '$device $lang $name',
          (t) async {
            await pumpScreen(
              t,
              session: session,
              path: path,
              language: lang,
              assessments: FakeAssessmentRepository(
                stage: stage ?? QuizStage.intro,
              ),
            );
            // The store's exact pixel size and density.
            t.view.physicalSize = size * ratio;
            t.view.devicePixelRatio = ratio;
            t.view.padding = FakeViewPadding(
              top: (device.startsWith('ipad') ? 24 : 59) * ratio,
              bottom: (device.startsWith('ipad') ? 20 : 34) * ratio,
            );
            await t.pump();
            await t.pump(const Duration(seconds: 2));
            await _save(t, 'build/store_screenshots/$device/$lang/$name.png');
          },
          skip: !_enabled,
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        );
      }
    }
  }
}
