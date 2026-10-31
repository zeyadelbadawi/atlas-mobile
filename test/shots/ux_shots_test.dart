@Tags(['shots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/atlas_app.dart';
import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/core/academy/academy.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:atlas_mobile/design/design.dart';
import 'package:atlas_mobile/features/results/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fake_learning.dart';
import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

/// Before/after pictures of a UX change, for review in chat:
///
///   SHOTS=before flutter test --tags shots test/shots   (on the old code)
///   SHOTS=after  flutter test --tags shots test/shots   (on the new code)
///
/// Writes `build/ux_shots/<before|after>/<name>.png`, and `<name>.json`
/// with the frame (in pixels) of what the change is about, so the
/// comparison can circle it. Not committed.
final _label = Platform.environment['SHOTS'];

/// Atlas Demo Academy: a yellow academy with a yellow logo, the case where
/// the logo vanished on a tile of its own colour.
/// An academy whose logo is white on transparent.
const whiteLogoAcademy = Academy(
  id: '00000000-0000-4000-8000-00000000000a',
  name: 'Nour Academy',
  host: 'nour.atlass.dpdns.org',
  primaryColor: '222 72% 46%',
);

const demo = Academy(
  id: '9a75db56-d639-4849-a5e2-1295eb02ca75',
  name: 'Atlas Demo Academy',
  host: 'demoo.atlass.dpdns.org',
  primaryColor: '44 100% 53%',
);

class AsDemoSignedIn extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    academy: demo,
    user: {'name': 'زياد البدوي', 'email': 'zeyad@example.com'},
  );
}

/// Serves the demo academy's real logo for its logo URL (tests have no
/// network), straight into the image cache.
Future<void> serveDemoLogo(
  WidgetTester t, {
  Academy academy = demo,
  String fixture = 'demo_logo.png',
}) async {
  final bytes = File('test/fixtures/$fixture').readAsBytesSync();
  final image = await t.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  });
  PaintingBinding.instance.imageCache.putIfAbsent(
    NetworkImage(academy.logoUrl.toString()),
    () => OneFrameImageStreamCompleter(
      Future.value(ImageInfo(image: image!.clone())),
    ),
  );
}

Future<void> _save(WidgetTester t, String name, Finder? focus) async {
  debugDisableShadows = false;
  void dirty(RenderObject o) {
    o.markNeedsPaint();
    o.visitChildren(dirty);
  }

  for (final v in t.binding.renderViews) {
    dirty(v);
  }
  // Let fades, implicit animations and off-clock work (logo measuring)
  // finish before the picture.
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 300));
  }
  final element = t.element(find.byType(AtlasApp));
  final dir = 'build/ux_shots/$_label';
  if (focus != null && focus.evaluate().isNotEmpty) {
    final r = t.getRect(focus.first);
    final k = t.view.devicePixelRatio;
    File('$dir/$name.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode([r.left * k, r.top * k, r.right * k, r.bottom * k]),
      );
  }
  await t.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

/// One picture; [focus] is the thing the change is about (circled).
void shot(
  String name,
  Future<void> Function(WidgetTester) arrange, {
  Finder Function()? focus,
  bool ios = false,
}) => testWidgets(
  name,
  (t) async {
    await arrange(t);
    await _save(t, name, focus?.call());
  },
  skip: _label == null,
  variant: ios
      ? TargetPlatformVariant.only(TargetPlatform.iOS)
      : TargetPlatformVariant.only(TargetPlatform.android),
);

void main() {
  setUpAll(loadGoldenFonts);
  resultsShot();

  shot('picker_recent_logo', (t) async {
    await serveDemoLogo(t);
    await serveDemoLogo(
      t,
      academy: whiteLogoAcademy,
      fixture: 'white_logo.png',
    );
    await pumpScreen(
      t,
      session: AsNoAcademy.new,
      size: const Size(393, 1100),
      recent: [demo, whiteLogoAcademy, ziadd],
    );
  }, focus: () => find.byType(AcademyLogo).first);

  shot('home_dark_logo', (t) async {
    await serveDemoLogo(t);
    await pumpScreen(
      t,
      session: AsDemoSignedIn.new,
      path: '/home',
      theme: ThemeMode.dark,
    );
  }, focus: () => find.byType(AcademyLogo).first);

  shot(
    'ipad_sidebar_logo',
    (t) async {
      await serveDemoLogo(t);
      await pumpScreen(
        t,
        session: AsDemoSignedIn.new,
        path: '/home',
        size: const Size(1032, 1376),
      );
    },
    ios: true,
    focus: () => find.descendant(
      of: find.byType(AtlasSidebar),
      matching: find.text('Atlas Demo Academy'),
    ),
  );

  completionShots();

  shot('courses_broken_cover', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/courses',
      learning: _BrokenCovers(),
    );
  }, focus: () => find.byType(CourseCover).first);
}

/// The scores in My results: passed and not passed.
void resultsShot() => shot('results_scores', (t) async {
  await pumpScreen(t, session: AsSignedIn.new, path: '/account/results');
}, focus: () => find.byType(ScoreText).at(1));

/// The first course has a cover image whose link does not load.
class _BrokenCovers extends FakeLearningRepository {
  @override
  Future<List<EnrolledCourse>> enrollments() async {
    final list = await super.enrollments();
    return [
      for (final (i, c) in list.indexed)
        i == 0
            ? EnrolledCourse.fromJson({
                'id': 'e-${c.courseId}',
                'courseId': c.courseId,
                'course': {
                  'title': c.title,
                  'thumbnail': 'https://cdn.example.test/missing.jpg',
                  'instructors': [
                    for (final n in c.instructors) {'name': n},
                  ],
                },
                'progress': {
                  'completedItems': c.completed,
                  'totalItems': c.total,
                  'percentage': c.total == 0 ? 0 : c.completed * 100 / c.total,
                  'learningState': 'in_progress',
                },
                'isActive': true,
              })
            : c,
    ];
  }
}

/// Batch 1 (A1): what the course still needs before it is completed.
void completionShots() {
  Finder checklistOr(String fallback) {
    final k = find.byKey(const ValueKey('completion-checklist'));
    return k.evaluate().isNotEmpty ? k : find.text(fallback);
  }

  shot('course_requirements', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}',
      size: const Size(393, 1500),
      learning: _WithRequirements(),
    );
  }, focus: () => checklistOr('استكمل'));

  shot('course_lessons_done_quiz_not_passed', (t) async {
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}',
      size: const Size(393, 1100),
      learning: _WithRequirements(allDone: true),
    );
  }, focus: () => checklistOr('أكملت الكورس'));
}

/// A course that needs its quiz passed, its assignment graded and an
/// overall score of 60%, with a certificate from 70%.
class _WithRequirements extends FakeLearningRepository {
  _WithRequirements({this.allDone = false});
  final bool allDone;

  @override
  Future<CourseSequence> sequence(String courseId) async {
    final j = FakeLearningRepository.sequenceJson;
    if (allDone) {
      for (final i in j['items'] as List) {
        (i as Map)['state'] = 'completed';
        i['lockReason'] = null;
      }
      j['completedCount'] = j['totalCount'];
      j['continueItemId'] = null;
    }
    return CourseSequence.fromJson(j);
  }

  @override
  Future<CourseCompletion> completion(String courseId) async =>
      CourseCompletion.fromJson({
        'completed': false,
        'lessons': {'total': 5, 'completed': allDone ? 5 : 2},
        'rule': {'lessons': 'all', 'minOverallScore': 60},
        'overallScore': allDone ? 45 : null,
        'quizzes': [
          {
            'quizId': 'l3',
            'title': 'كويز النهايات',
            'required': true,
            'passed': false,
            'effectiveScore': allDone ? 45 : null,
            'pendingGrading': false,
          },
        ],
        'assignments': [
          {
            'assignmentId': 'l6',
            'title': 'واجب الاتصال',
            'required': true,
            'submitted': allDone,
            'graded': false,
            'score': null,
          },
        ],
        'missing': [
          {'kind': 'quiz_not_passed', 'id': 'l3'},
        ],
        'certificate': {
          'enabled': true,
          'status': 'unavailable',
          'minScore': 70,
        },
      });
}
