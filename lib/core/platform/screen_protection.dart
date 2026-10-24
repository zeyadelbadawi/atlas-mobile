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
      return CaptureEvent.captured(map['captured'] == true);
    });
  }
}

class CaptureEvent {
  const CaptureEvent.captured(this.isCaptured) : isScreenshot = false;
  const CaptureEvent.screenshot() : isCaptured = false, isScreenshot = true;

  final bool isCaptured;
  final bool isScreenshot;
}
