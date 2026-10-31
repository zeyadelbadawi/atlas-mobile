import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/platform/biometrics.dart';
import 'providers.dart';

final biometricsProvider = Provider<Biometrics>((_) => DeviceBiometrics());

/// Whether the phone can lock the app (shown in Security only then).
final appLockAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricsProvider).available(),
);

@immutable
class AppLockState {
  const AppLockState({this.enabled = false, this.locked = false});
  final bool enabled;

  /// Covered by the lock screen until the owner confirms.
  final bool locked;
}

/// An optional lock with the phone's fingerprint, face or PIN: at launch,
/// and when the app comes back after [away] or more. Only while signed in
/// (there is nothing of the learner's to hide before).
class AppLockController extends Notifier<AppLockState> {
  static const _key = 'security.appLock';
  static const away = Duration(seconds: 30);

  DateTime? _leftAt;
  bool _checking = false;

  @override
  AppLockState build() {
    final enabled = ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
    final life = AppLifecycleListener(
      onHide: () => _leftAt ??= clockNow(),
      onShow: _back,
    );
    ref.onDispose(life.dispose);
    return AppLockState(enabled: enabled, locked: enabled);
  }

  bool get _signedIn =>
      ref.read(sessionProvider).status == SessionStatus.signedIn;

  void _back() {
    final left = _leftAt;
    _leftAt = null;
    // The phone's own prompt hides the app too: not a time away.
    if (_checking || !state.enabled || left == null) return;
    if (clockNow().difference(left) >= away) {
      state = AppLockState(enabled: true, locked: true);
    }
  }

  /// Whether the lock screen shows now.
  bool get covering => state.locked && _signedIn;

  Future<bool> unlock(String reason) async {
    if (_checking) return false;
    _checking = true;
    try {
      final ok = await ref.read(biometricsProvider).check(reason);
      if (ok) state = AppLockState(enabled: state.enabled);
      return ok;
    } finally {
      _checking = false;
      _leftAt = null;
    }
  }

  /// Turning it on asks first, so the learner knows it works on this phone.
  Future<bool> setEnabled(bool on, String reason) async {
    if (on) {
      _checking = true;
      try {
        if (!await ref.read(biometricsProvider).check(reason)) return false;
      } finally {
        _checking = false;
        _leftAt = null;
      }
    }
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
    state = AppLockState(enabled: on);
    return true;
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
