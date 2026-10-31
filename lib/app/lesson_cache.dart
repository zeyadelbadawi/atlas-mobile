import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/learning_models.dart';
import 'providers.dart';

/// Text lessons the learner opened, kept on the phone so they can be read
/// again without a connection. Only text: video stays protected and
/// online, and a file needs its link. Per account and academy; the 30
/// most recent, each up to 200 KB of text.
class LessonCache {
  LessonCache(this._ref);
  final Ref _ref;

  static const prefix = 'offline.lessons.';
  static const keep = 30;
  static const maxChars = 200000;

  String? get _key {
    final s = _ref.read(sessionProvider);
    final user = s.user?['id'];
    if (s.academy == null || user == null) return null;
    return '$prefix${s.academy!.id}.$user';
  }

  /// The kept lessons, newest first.
  List<Map<String, dynamic>> _all(String key) {
    final raw = _ref.read(sharedPreferencesProvider).getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } on Object {
      return [];
    }
  }

  static bool keepable(LessonGrant g) =>
      g.kind == 'text' &&
      g.youtubeId == null &&
      g.hostedVideoUrl == null &&
      (g.bodyHtml ?? '').isNotEmpty &&
      g.bodyHtml!.length <= maxChars;

  Future<void> save(LessonGrant g) async {
    final key = _key;
    if (key == null || !keepable(g)) return;
    final rest = _all(key).where((m) => m['lessonId'] != g.lessonId);
    final next = [g.raw, ...rest].take(keep).toList();
    await _ref.read(sharedPreferencesProvider).setString(key, jsonEncode(next));
  }

  LessonGrant? load(String lessonId) {
    final key = _key;
    if (key == null) return null;
    final m = _all(key).where((m) => m['lessonId'] == lessonId).firstOrNull;
    if (m == null) return null;
    try {
      return LessonGrant.fromJson(m);
    } on Object {
      return null;
    }
  }
}

final lessonCacheProvider = Provider<LessonCache>(LessonCache.new);
