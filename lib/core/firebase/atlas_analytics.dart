import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Analytics for Firebase, kept to what the product needs:
///
/// * screen names are route TEMPLATES (`/course/:id/quiz/:quizId`), never
///   ids, names, emails or answers;
/// * a few learning events with non-identifying parameters;
/// * no advertising ID (disabled in the Android manifest and iOS plist);
/// * the learner can switch it off in Account, and the choice is kept.
///
/// When Firebase is not configured (tests, a build without the config file)
/// every call is a no-op.
class AtlasAnalytics {
  AtlasAnalytics({required this.available, required SharedPreferences prefs})
    : _prefs = prefs; // ignore: prefer_initializing_formals

  static const _key = 'analytics.enabled';

  final bool available;
  final SharedPreferences _prefs;
  String? _lastScreen;

  bool get enabled => _prefs.getBool(_key) ?? true;

  FirebaseAnalytics? get _fa => available ? FirebaseAnalytics.instance : null;

  /// Applies the stored choice at startup.
  Future<void> applyStoredChoice() async =>
      _guard(() => _fa?.setAnalyticsCollectionEnabled(enabled));

  Future<void> setEnabled(bool on) async {
    await _prefs.setBool(_key, on);
    await _guard(() => _fa?.setAnalyticsCollectionEnabled(on));
  }

  void screen(String template) {
    if (!enabled || template == _lastScreen) return;
    _lastScreen = template;
    unawaited(
      _guard(
        () => _fa?.logScreenView(screenName: template, screenClass: template),
      ),
    );
  }

  /// [params] must never carry personal data: types, counts, booleans.
  void event(String name, [Map<String, Object>? params]) {
    if (!enabled) return;
    unawaited(_guard(() => _fa?.logEvent(name: name, parameters: params)));
  }

  Future<void> _guard(Future<void>? Function() call) async {
    try {
      await call();
    } on Object catch (e) {
      debugPrint('analytics: $e');
    }
  }
}
