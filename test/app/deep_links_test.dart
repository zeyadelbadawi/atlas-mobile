import 'package:atlas_mobile/app/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

AcademyLink? parse(String s) => parseAcademyLink(Uri.parse(s));

String? screen(String s) => switch (parse(s)?.action) {
  OpenScreen(:final path) => path,
  _ => null,
};

void main() {
  const host = 'ziadd.atlass.dpdns.org';

  test('host is kept, lower-cased', () {
    expect(parse('https://ZIADD.atlass.dpdns.org/')!.host, host);
  });

  test('catalog and course pages, with or without a language prefix', () {
    expect(screen('https://$host/courses'), '/catalog');
    expect(screen('https://$host/courses/algebra-1'), '/catalog/algebra-1');
    expect(screen('https://$host/ar/courses/algebra-1'), '/catalog/algebra-1');
    expect(screen('https://$host/en/courses/'), '/catalog');
  });

  test('learner pages map like notification links', () {
    expect(
      screen('https://$host/my/courses/c1/learn/l2'),
      '/course/c1/lesson/l2',
    );
    expect(screen('https://$host/ar/my/certificates'), '/account/certificates');
  });

  test('emailed links carry their token', () {
    final verify = parse('https://$host/verify-email?token=abc')!.action;
    expect(verify, isA<VerifyEmailLink>());
    expect((verify as VerifyEmailLink).token, 'abc');
    final reset = parse('https://$host/ar/reset-password?token=xyz')!.action;
    expect((reset as ResetPasswordLink).token, 'xyz');
  });

  test('a token-less emailed link still lands somewhere useful', () {
    expect(screen('https://$host/verify-email'), '/account/profile');
    expect(screen('https://$host/reset-password'), '/academy/forgot');
    expect(screen('https://$host/forgot-password'), '/academy/forgot');
  });

  test('paying and certificate checks stay on the web', () {
    for (final p in [
      '/my/purchases',
      '/ar/my/payments/p1',
      '/my/courses/c1/checkout',
      '/verify/ABC123',
    ]) {
      expect(parse('https://$host$p')!.action, isA<OpenInBrowser>(), reason: p);
    }
  });

  test('any other page just opens the academy', () {
    for (final p in ['/', '/about', '/sign-in', '/pricing']) {
      expect(parse('https://$host$p')!.action, isA<OpenAcademy>(), reason: p);
    }
  });

  test('typed without a scheme', () {
    expect(screen('$host/courses/x'), '/catalog/x');
  });

  test('not an academy address', () {
    expect(parse('mailto:a@b.c'), isNull);
    expect(parse('ziadd'), isNull);
    expect(parse('ftp://$host/courses'), isNull);
  });
}
