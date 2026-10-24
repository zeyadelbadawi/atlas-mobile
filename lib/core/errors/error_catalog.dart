import 'dart:convert';

import 'package:flutter/services.dart';

import '../api/api_error.dart';

/// The web's error texts (`assets/l10n/errors_<lang>.json`, synced with
/// tool/sync_web_errors.sh), looked up by the backend's `messageKey`.
class ErrorCatalog {
  ErrorCatalog(this._byLanguage);

  final Map<String, Map<String, dynamic>> _byLanguage;

  static Future<ErrorCatalog> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final out = <String, Map<String, dynamic>>{};
    for (final lang in ['en', 'ar']) {
      out[lang] = jsonDecode(
        await b.loadString('assets/l10n/errors_$lang.json'),
      ) as Map<String, dynamic>;
    }
    return ErrorCatalog(out);
  }

  /// `errors.auth.otpInvalid` → text. Walks up to the closest group that has
  /// a `description`, then falls back to the generic message.
  String message(String messageKey, String languageCode) {
    final root = _byLanguage[languageCode] ?? _byLanguage['en']!;
    var parts = messageKey.split('.');
    if (parts.isNotEmpty && parts.first == 'errors') parts = parts.sublist(1);
    while (parts.isNotEmpty) {
      Object? node = root;
      for (final p in parts) {
        node = node is Map ? node[p] : null;
      }
      if (node is String) return node;
      if (node is Map && node['description'] is String) {
        return node['description'] as String;
      }
      parts = parts.sublist(0, parts.length - 1);
    }
    final unknown = root['unknown'];
    return unknown is Map
        ? unknown['description'] as String
        : 'Something went wrong.';
  }

  String of(Object error, String languageCode) => error is AtlasApiException
      ? message(error.messageKey, languageCode)
      : message('errors.unknown', languageCode);
}
