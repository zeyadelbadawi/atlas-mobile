import 'dart:convert';

import 'package:flutter/services.dart';

/// One of Atlas's legal documents, bundled with the app
/// (`assets/legal/<id>.<lang>.json`, copied from the web's typed content by
/// `tool/sync_legal.mjs`), so it opens instantly and offline, and reads
/// exactly as on the website.
class LegalDocument {
  LegalDocument.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String? ?? '',
      summary = j['summary'] as String? ?? '',
      effectiveDate = j['effectiveDate'] as String? ?? '',
      lastUpdated = j['lastUpdated'] as String? ?? '',
      sections = [
        for (final s in (j['sections'] as List? ?? const []))
          LegalSection.fromJson(s as Map<String, dynamic>),
      ];

  final String title, summary, effectiveDate, lastUpdated;
  final List<LegalSection> sections;

  static Future<LegalDocument> load(
    String id,
    String languageCode, {
    AssetBundle? bundle,
  }) async {
    final lang = languageCode == 'ar' ? 'ar' : 'en';
    final raw = await (bundle ?? rootBundle).loadString(
      'assets/legal/$id.$lang.json',
    );
    return LegalDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

class LegalSection {
  LegalSection.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      heading = j['heading'] as String? ?? '',
      blocks = [
        for (final b in (j['blocks'] as List? ?? const []))
          LegalBlock.fromJson(b as Map<String, dynamic>),
      ];

  final String id, heading;
  final List<LegalBlock> blocks;
}

/// A paragraph, a bulleted list, or a list of term / explanation pairs.
sealed class LegalBlock {
  const LegalBlock();

  factory LegalBlock.fromJson(Map<String, dynamic> j) => switch (j['kind']) {
    'list' => LegalList([
      for (final i in (j['items'] as List? ?? const [])) i as String,
    ]),
    'definitions' => LegalDefinitions([
      for (final i in (j['items'] as List? ?? const []))
        (
          term: (i as Map)['term'] as String? ?? '',
          detail: i['detail'] as String? ?? '',
        ),
    ]),
    _ => LegalParagraph(j['text'] as String? ?? ''),
  };
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);
  final String text;
}

class LegalList extends LegalBlock {
  const LegalList(this.items);
  final List<String> items;
}

class LegalDefinitions extends LegalBlock {
  const LegalDefinitions(this.items);
  final List<({String term, String detail})> items;
}
