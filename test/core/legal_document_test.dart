import 'package:atlas_mobile/core/legal/legal_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['privacy', 'terms']) {
    test(
      '$id: Arabic and English parse and match section for section',
      () async {
        final ar = await LegalDocument.load(id, 'ar');
        final en = await LegalDocument.load(id, 'en');
        expect(ar.sections, isNotEmpty);
        expect(ar.title, isNotEmpty);
        expect(ar.lastUpdated, isNotEmpty);
        expect(
          ar.sections.map((s) => s.id).toList(),
          en.sections.map((s) => s.id).toList(),
        );
        for (final (i, s) in ar.sections.indexed) {
          expect(s.heading, isNotEmpty);
          expect(s.blocks.length, en.sections[i].blocks.length, reason: s.id);
          for (final (j, b) in s.blocks.indexed) {
            expect(
              b.runtimeType,
              en.sections[i].blocks[j].runtimeType,
              reason: '${s.id} block $j',
            );
          }
        }
      },
    );
  }

  test('an unknown language falls back to English', () async {
    final doc = await LegalDocument.load('terms', 'fr');
    final en = await LegalDocument.load('terms', 'en');
    expect(doc.title, en.title);
  });
}
