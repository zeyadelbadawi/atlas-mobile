import 'dart:async';
import 'dart:ui';

import 'package:atlas_mobile/core/platform/screen_protection.dart';
import 'package:atlas_mobile/features/quiz/quiz_guard.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProtection extends ScreenProtection {
  final calls = <String>[];
  // Closed in tearDown.
  // ignore: close_sinks
  final events = StreamController<CaptureEvent>.broadcast();
  bool captured = false, pinned = false, pinWorks = true;

  @override
  Future<bool> setSecure(bool on) async {
    calls.add('secure:$on');
    return true;
  }

  @override
  Future<bool> setHideOverlays(bool on) async {
    calls.add('overlays:$on');
    return true;
  }

  @override
  Future<bool> setDataSensitive(bool on) async {
    calls.add('sensitive:$on');
    return true;
  }

  @override
  Future<bool> isCaptured() async => captured;

  @override
  Stream<CaptureEvent> get captureChanges => events.stream;

  @override
  Future<bool> startPin() async {
    calls.add('startPin');
    return pinWorks;
  }

  @override
  Future<bool> stopPin() async {
    calls.add('stopPin');
    pinned = false;
    return true;
  }

  @override
  Future<bool> isPinned() async => pinned;
}

void main() {
  late FakeProtection p;
  late List<String> sent;
  var changes = 0;

  QuizGuard guard({bool lock = false, TargetPlatform? platform}) => QuizGuard(
    protection: p,
    onEvent: (type, [payload]) =>
        sent.add(payload == null ? type : '$type:${payload['reason']}'),
    onChanged: () => changes++,
    lock: lock,
    platform: platform ?? TargetPlatform.android,
  );

  setUp(() {
    p = FakeProtection();
    addTearDown(p.events.close);
    sent = [];
    changes = 0;
  });

  test('blocks capture and overlays for the quiz, and lifts them after', () {
    fakeAsync((async) {
      final g = guard()..start();
      async.flushMicrotasks();
      expect(p.calls, ['secure:true', 'overlays:true', 'sensitive:true']);
      g.dispose();
      async.flushMicrotasks();
      expect(p.calls.skip(3), [
        'secure:false',
        'overlays:false',
        'sensitive:false',
      ]);
      expect(sent, isEmpty);
    });
  });

  test(
    'iOS: screenshots and capture are reported; capture hides the questions',
    () {
      fakeAsync((async) {
        final g = guard(platform: TargetPlatform.iOS)..start();
        async.flushMicrotasks();
        p.events.add(const CaptureEvent.screenshot());
        p.events.add(const CaptureEvent.captured(true));
        async.flushMicrotasks();
        expect(g.captured, isTrue);
        p.events.add(const CaptureEvent.captured(true)); // no change
        p.events.add(const CaptureEvent.captured(false));
        async.flushMicrotasks();
        expect(g.captured, isFalse);
        expect(sent, [
          'screenshot',
          'screen_capture_start',
          'screen_capture_stop',
        ]);
        g.dispose();
      });
    },
  );

  test('already recording when the quiz opens: hidden from the start', () {
    fakeAsync((async) {
      p.captured = true;
      final g = guard(platform: TargetPlatform.iOS)..start();
      async.flushMicrotasks();
      expect(g.captured, isTrue);
      expect(sent, ['screen_capture_start']);
      g.dispose();
    });
  });

  test('Android pinning: pinned, unpinned (recorded), pinned again', () {
    fakeAsync((async) {
      final g = guard(lock: true)..start();
      async.flushMicrotasks();
      expect(p.calls, contains('startPin'));
      p.pinned = true;
      async.elapse(const Duration(seconds: 2));
      expect(g.pin, PinState.pinned);
      expect(sent, isEmpty);
      p.pinned = false;
      async.elapse(const Duration(seconds: 2));
      expect(g.pin, PinState.lost);
      expect(g.canPin, isTrue);
      g.pinAgain();
      p.pinned = true;
      async.elapse(const Duration(seconds: 2));
      expect(g.pin, PinState.pinned);
      expect(sent, ['fullscreen_exit', 'fullscreen_enter']);
      g.dispose();
      async.flushMicrotasks();
      expect(p.calls.last, 'stopPin');
    });
  });

  test('Android pinning refused: recorded once, the learner can pin later', () {
    fakeAsync((async) {
      final g = guard(lock: true)..start();
      async.elapse(const Duration(seconds: 12));
      expect(g.pin, PinState.unavailable);
      expect(g.canPin, isTrue);
      expect(sent, ['fullscreen_unavailable:refused']);
      async.elapse(const Duration(seconds: 20));
      expect(sent, hasLength(1));
      g.dispose();
    });
  });

  test(
    'iOS assessment mode: begins, or is unavailable without the entitlement',
    () {
      fakeAsync((async) {
        final g = guard(lock: true, platform: TargetPlatform.iOS)..start();
        async.flushMicrotasks();
        expect(g.pin, PinState.pinned);
        p.events.add(const CaptureEvent.unpinned());
        async.flushMicrotasks();
        expect(g.pin, PinState.lost);
        expect(g.canPin, isFalse); // nothing the learner can do on iOS
        expect(sent, ['fullscreen_exit']);
        g.dispose();

        p.pinWorks = false;
        sent.clear();
        final h = guard(lock: true, platform: TargetPlatform.iOS)..start();
        async.flushMicrotasks();
        expect(h.pin, PinState.unavailable);
        expect(sent, ['fullscreen_unavailable:unsupported']);
        h.dispose();
      });
    },
  );

  test('side by side: a window much smaller than the screen', () {
    const display = Size(1080, 2400);
    expect(isSideBySide(display, display), isFalse);
    expect(isSideBySide(const Size(1080, 2300), display), isFalse);
    expect(isSideBySide(const Size(1080, 1150), display), isTrue);
    expect(isSideBySide(const Size(1080, 1150), Size.zero), isFalse);
  });
}
