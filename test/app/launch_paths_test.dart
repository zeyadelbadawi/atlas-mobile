// A path from a home-screen widget tap or an app-icon shortcut (both carry
// an externally-invocable URL scheme) is navigated to only when it is one
// the app itself emits.
import 'package:atlas_mobile/app/launch_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the paths the widget and shortcuts emit are allowed', () {
    for (final p in [
      '/home',
      '/courses',
      '/tasks',
      '/notifications',
      '/account/notes',
      '/course/c-calc',
      '/course/c-calc/lesson/l2',
      '/course/abc_123.def~4-5',
    ]) {
      expect(safeLaunchPath(p), p, reason: p);
    }
  });

  test('anything else is rejected', () {
    for (final p in [
      null,
      '',
      'home',
      '//evil.com',
      '/account/security',
      '/account/devices',
      '/academy/sign-in',
      '/course/..%2f..%2fetc',
      '/course/../secret',
      '/course/',
      '/course',
      '/course//x',
      '/home?x=1',
      '/home#y',
      r'/home\..\evil',
      'https://evil.com/home',
      '/picker',
      '/legal/terms',
    ]) {
      expect(safeLaunchPath(p), isNull, reason: '$p');
    }
  });
}
