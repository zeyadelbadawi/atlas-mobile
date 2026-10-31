import 'package:atlas_mobile/app/providers.dart';
import 'package:flutter_test/flutter_test.dart';

String first(String name) => SessionState(
  status: SessionStatus.signedIn,
  user: {'name': name},
).firstName;

void main() {
  test('greets by the first name, keeping compound names whole', () {
    expect(first('زياد البدوي'), 'زياد');
    expect(first('عبد الرحمن محمد'), 'عبد الرحمن');
    expect(first('أبو بكر الصديق'), 'أبو بكر');
    expect(first('Abdel Rahman Ali'), 'Abdel Rahman');
    expect(first('Sara  Ahmed'), 'Sara');
    expect(first('عبد'), 'عبد');
    expect(first(''), '');
  });
}
