import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/screen_protection.dart';

/// The phone's capture and lock controls (overridden in tests).
final screenProtectionProvider = Provider<ScreenProtection>(
  (ref) => ScreenProtection(),
);

/// Where the phone lock stands during a quiz that asks for it.
enum PinState {
  /// Not asked for, or not started yet.
  off,

  /// The phone is locked to the quiz (Android screen pinning, iOS
  /// assessment mode).
  pinned,

  /// It was on and the learner (or the system) turned it off.
  lost,

  /// It never took effect: refused on Android, not available on iOS.
  unavailable,
}

/// The phone's side of a monitored quiz: what it blocks and what it reports.
///
/// * Screenshots, recording and casting: blocked on Android (secure flag).
///   iOS cannot block them; a screenshot is reported once taken, and while
///   the screen is recorded or mirrored the questions are hidden
///   ([captured]) and that is reported too.
/// * Other apps' floating windows are not drawn over the quiz (Android 12+).
/// * With [lock], the phone is locked to the quiz: screen pinning on
///   Android (the learner confirms it and can undo it, which is reported),
///   Apple's assessment mode on iOS when Atlas has the entitlement.
///
/// Events go to [onEvent] with the server's event names; [onChanged] is
/// called whenever [captured] or [pin] changes.
class QuizGuard {
  QuizGuard({
    required this.protection,
    required this.onEvent,
    required this.onChanged,
    required this.lock,
    TargetPlatform? platform,
    this.pollEvery = const Duration(seconds: 2),
    this.pinWait = const Duration(seconds: 10),
  }) : platform = platform ?? defaultTargetPlatform;

  final ScreenProtection protection;
  final void Function(String type, [Map<String, Object?>? payload]) onEvent;
  final VoidCallback onChanged;
  final bool lock;
  final TargetPlatform platform;
  final Duration pollEvery, pinWait;

  bool captured = false;
  PinState pin = PinState.off;

  StreamSubscription<CaptureEvent>? _capture;
  Timer? _poll;

  /// Polls since pinning was asked for and not yet confirmed.
  int? _waitedPolls;
  bool _stopped = false;

  bool get _ios => platform == TargetPlatform.iOS;

  /// Whether the learner can do something about the lock (pin again).
  bool get canPin =>
      lock && !_ios && (pin == PinState.lost || pin == PinState.unavailable);

  Future<void> start() async {
    unawaited(protection.setSecure(true));
    unawaited(protection.setHideOverlays(true));
    _capture = protection.captureChanges.listen(
      _onCapture,
      onError: (Object _) {}, // no capture reports on this phone
    );
    if (await protection.isCaptured()) _setCaptured(true);
    if (lock) await _startPin();
  }

  void _onCapture(CaptureEvent e) {
    if (_stopped) return;
    if (e.isScreenshot) {
      onEvent('screenshot');
    } else if (e.isUnpinned) {
      _lost();
    } else {
      _setCaptured(e.isCaptured);
    }
  }

  void _setCaptured(bool on) {
    if (on == captured || _stopped) return;
    captured = on;
    onEvent(on ? 'screen_capture_start' : 'screen_capture_stop');
    onChanged();
  }

  Future<void> _startPin() async {
    final ok = await protection.startPin();
    if (_stopped) return;
    if (_ios) {
      // Assessment mode answers once the session began, or failed to.
      _set(ok ? PinState.pinned : PinState.unavailable);
      if (!ok) onEvent('fullscreen_unavailable', {'reason': 'unsupported'});
      return;
    }
    if (!ok) {
      _unavailable('unsupported');
      return;
    }
    // Android shows a confirmation; the state is read until it is pinned.
    _waitedPolls = 0;
    _poll ??= Timer.periodic(pollEvery, (_) => unawaited(_check()));
  }

  /// The learner taps "Pin the screen" after unpinning or refusing.
  Future<void> pinAgain() async {
    if (!canPin) return;
    await _startPin();
  }

  Future<void> _check() async {
    if (_stopped) return;
    final on = await protection.isPinned();
    if (_stopped) return;
    if (on) {
      if (pin != PinState.pinned) {
        // Back after an unpin (the first pin is the quiz's own start).
        if (pin == PinState.lost || pin == PinState.unavailable) {
          onEvent('fullscreen_enter');
        }
        _waitedPolls = null;
        _set(PinState.pinned);
      }
    } else if (pin == PinState.pinned) {
      _lost();
    } else if (_waitedPolls != null &&
        (_waitedPolls = _waitedPolls! + 1) * pollEvery.inMilliseconds >=
            pinWait.inMilliseconds) {
      _waitedPolls = null;
      if (pin == PinState.off) _unavailable('refused');
    }
  }

  void _lost() {
    if (pin != PinState.pinned) return;
    onEvent('fullscreen_exit');
    _set(PinState.lost);
  }

  void _unavailable(String reason) {
    onEvent('fullscreen_unavailable', {'reason': reason});
    _set(PinState.unavailable);
  }

  void _set(PinState next) {
    if (pin == next) return;
    pin = next;
    onChanged();
  }

  Future<void> dispose() async {
    _stopped = true;
    _poll?.cancel();
    unawaited(protection.setSecure(false));
    unawaited(protection.setHideOverlays(false));
    if (lock) unawaited(protection.stopPin());
    await _capture?.cancel();
  }
}

/// The quiz is shown in a window smaller than the screen: split screen, a
/// pop-up window, or next to another app on an iPad.
bool isSideBySide(Size window, Size display) {
  if (display.isEmpty || window.isEmpty) return false;
  return window.width * window.height < display.width * display.height * 0.75;
}
