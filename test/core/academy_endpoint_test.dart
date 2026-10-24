import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:test/test.dart';

void main() {
  group('AcademyEndpoint.parse', () {
    test('adds https to a bare host and drops the path', () {
      final e = AcademyEndpoint.parse(
        ' Ziadd.atlass.dpdns.org/ar/courses?x=1 ',
      );
      expect(e.originHeader, 'https://ziadd.atlass.dpdns.org');
      expect(e.apiBase, 'https://ziadd.atlass.dpdns.org/api/v1/');
    });

    test('omits a default port and keeps a custom one', () {
      expect(
        AcademyEndpoint.parse('https://a.b:443').originHeader,
        'https://a.b',
      );
      expect(
        AcademyEndpoint.parse('http://web-development-academy:3000')
            .originHeader,
        'http://web-development-academy:3000',
      );
    });

    test('refuses input with no host or a foreign scheme', () {
      expect(() => AcademyEndpoint.parse(''), throwsFormatException);
      expect(() => AcademyEndpoint.parse('ftp://a.b'), throwsFormatException);
    });

    test('two spellings of one origin are equal', () {
      expect(
        AcademyEndpoint.parse('HTTPS://A.B/x'),
        AcademyEndpoint.parse('a.b'),
      );
    });
  });
}
