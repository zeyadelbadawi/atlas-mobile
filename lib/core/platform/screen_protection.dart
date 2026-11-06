import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the phone can do about screen capture while a lesson is open.
///
/// * Android: `FLAG_SECURE` — screenshots, recordings, casting and the
///   recents thumbnail show black.
/// * iOS: recording cannot be blocked. The app learns when the screen is
///   being recorded or mirrored ([captureChanges]) and when a screenshot
///   was taken, and pauses/blurs the video.
///
/// Neither makes a recording impossible (a camera pointed at the screen
/// still works); the watermark is what traces a leak.
class ScreenProtection {
  ScreenProtection({MethodChannel? methods, EventChannel? events})
    : _methods = methods ?? const MethodChannel('atlas/screen_protection'),
      _events = events ?? const EventChannel('atlas/screen_capture/events');

  final MethodChannel _methods;
  final EventChannel _events;

  /// Turns Android's secure flag on or off. Returns whether the platform
  /// applied it (always false on iOS).
  Future<bool> setSecure(bool on) async {
    try {
      return await _methods.invokeMethod<bool>('setSecure', on) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('screen protection: $e');
      return false;
    }
  }

  /// Android 12+: other apps' floating windows are not drawn over this app.
  Future<bool> setHideOverlays(bool on) => _call('setHideOverlays', on);

  /// Android 14+: the screen's content is hidden from accessibility
  /// services that are not assistive tools (apps that read the screen to
  /// answer questions); TalkBack and other real tools still work.
  Future<bool> setDataSensitive(bool on) => _call('setDataSensitive', on);

  /// Locks the phone to the app for a quiz: screen pinning on Android (the
  /// learner confirms, and can unpin), Apple's assessment mode on iOS
  /// (when Atlas has the entitlement). Returns whether it took effect.
  Future<bool> startPin() => _call('startPin');
  Future<bool> stopPin() => _call('stopPin');
  Future<bool> isPinned() => _call('isPinned');

  Future<bool> _call(String method, [Object? argument]) async {
    try {
      return await _methods.invokeMethod<bool>(method, argument) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('screen protection $method: $e');
      return false;
    }
  }

  Future<bool> isCaptured() async {
    try {
      return await _methods.invokeMethod<bool>('isCaptured') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// iOS: `CaptureEvent.captured(bool)` when recording/mirroring starts or
  /// stops, `CaptureEvent.screenshot` after a screenshot. Empty on Android.
  Stream<CaptureEvent> get captureChanges {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const Stream.empty();
    }
    return _events.receiveBroadcastStream().map((raw) {
      final map = Map<String, Object?>.from(raw as Map);
      if (map['screenshot'] == true) return const CaptureEvent.screenshot();
      if (map['pinned'] == false) return const CaptureEvent.unpinned();
      return CaptureEvent.captured(map['captured'] == true);
    });
  }
}

class CaptureEvent {
  const CaptureEvent.captured(this.isCaptured)
    : isScreenshot = false,
      isUnpinned = false;
  const CaptureEvent.screenshot()
    : isCaptured = false,
      isScreenshot = true,
      isUnpinned = false;

  /// iOS: the system ended the assessment-mode session (a call, for one).
  const CaptureEvent.unpinned()
    : isCaptured = false,
      isScreenshot = false,
      isUnpinned = true;

  final bool isCaptured;
  final bool isScreenshot;
  final bool isUnpinned;
}
