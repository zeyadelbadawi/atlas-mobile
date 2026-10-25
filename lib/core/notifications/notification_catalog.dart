import 'dart:convert';

import 'package:flutter/services.dart';

/// The web's notification texts (`assets/l10n/notifications_<lang>.json`,
/// synced with tool/sync_web_notifications.sh). A notification arrives as
/// `titleKey`/`messageKey` + `values`; this turns it into the same words the
/// web shows, with `{{name}}` filled from the values.
class NotificationCatalog {
  NotificationCatalog(this._byLanguage);

  final Map<String, Map<String, dynamic>> _byLanguage;

  static Future<NotificationCatalog> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final out = <String, Map<String, dynamic>>{};
    for (final lang in ['en', 'ar']) {
      out[lang] = jsonDecode(
        await b.loadString('assets/l10n/notifications_$lang.json'),
      ) as Map<String, dynamic>;
    }
    return NotificationCatalog(out);
  }

  /// `notifications:events.assignmentGraded.title` → text, or null when the
  /// key is unknown (an event newer than this build).
  String? text(
    String key,
    String languageCode, [
    Map<String, dynamic> values = const {},
    String Function(String)? digits,
  ]) {
    final root = _byLanguage[languageCode] ?? _byLanguage['en']!;
    final path = key.contains(':') ? key.split(':').last : key;
    Object? node = root;
    for (final p in path.split('.')) {
      node = node is Map ? node[p] : null;
    }
    if (node is! String) return null;
    return node.replaceAllMapped(RegExp(r'\{\{\s*(\w+)\s*\}\}'), (m) {
      final v = values[m[1]];
      if (v == null) return '';
      final s = v is num ? _number(v) : '$v';
      return digits != null && v is num ? digits(s) : s;
    });
  }

  /// A label from the catalogue's own groups (`types.activity`, ...).
  String? label(String path, String languageCode) => text(path, languageCode);

  static String _number(num v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
}
