import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// The phone's own lock: fingerprint, face, or its PIN / passcode.
abstract class Biometrics {
  /// Whether the phone has a way to check it is its owner.
  Future<bool> available();

  /// Asks; true when the owner confirmed.
  Future<bool> check(String reason);
}

class DeviceBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object catch (e) {
      debugPrint('biometrics: $e');
      return false;
    }
  }

  @override
  Future<bool> check(String reason) async {
    try {
      // Fingerprint or face first; the phone's PIN when those fail, so a
      // learner is never locked out of their own app.
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Object catch (e) {
      debugPrint('biometrics: $e');
      return false;
    }
  }
}
