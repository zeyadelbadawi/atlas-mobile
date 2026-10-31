import 'package:atlas_mobile/core/platform/biometrics.dart';

/// The phone's lock, answered by the test.
class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.supported = false, this.passes = true});
  bool supported;
  bool passes;
  int asked = 0;

  @override
  Future<bool> available() async => supported;

  @override
  Future<bool> check(String reason) async {
    asked++;
    return passes;
  }
}
