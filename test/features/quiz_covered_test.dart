// Notifications or Control Center pulled over a monitored quiz: recorded as
// focus lost only past two seconds.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fake_assessment.dart';
import '../app/fake_learning.dart';
import '../app/screen_harness.dart';
import '../design/golden_harness.dart';

void _quietPhone(WidgetTester t) {
  const methods = MethodChannel('atlas/screen_protection');
  const events = EventChannel('atlas/screen_capture/events');
  final m = t.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(methods, (call) async => false);
  m.setMockStreamHandler(events, MockStreamHandler.inline(onListen: (_, _) {}));
  addTearDown(() {
    m
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null);
  });
}

List<String> _types(FakeAssessmentRepository r) => [
  for (final e in r.recorded)
    if (e['type'] != 'heartbeat') e['type']! as String,
];

void main() {
  setUpAll(loadGoldenFonts);

  Future<FakeAssessmentRepository> open(WidgetTester t, String mode) async {
    _quietPhone(t);
    final repo = FakeAssessmentRepository(
      stage: QuizStage.running,
      sessionIntegrity: mode,
    );
    await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/course/${FakeLearningRepository.courseId}/quiz/l3',
      assessments: repo,
    );
    await t.pump(const Duration(milliseconds: 300));
    return repo;
  }

  Future<void> cover(WidgetTester t, Duration d) async {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump(d);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump(const Duration(seconds: 3)); // the next send
  }

  testWidgets('a glance at the notifications is not recorded', (t) async {
    final repo = await open(t, 'warn');
    await cover(t, const Duration(seconds: 1));
    expect(_types(repo), isNot(contains('blur')));
  });

  testWidgets('notifications pulled down for longer: focus lost, then back', (
    t,
  ) async {
    final repo = await open(t, 'warn');
    await cover(t, const Duration(seconds: 3));
    final types = _types(repo);
    expect(types.where((x) => x == 'blur'), hasLength(1));
    expect(types.indexOf('focus'), greaterThan(types.indexOf('blur')));
  });

  testWidgets('unmonitored quiz: nothing recorded', (t) async {
    final repo = await open(t, 'off');
    await cover(t, const Duration(seconds: 3));
    expect(repo.recorded, isEmpty);
  });
}
