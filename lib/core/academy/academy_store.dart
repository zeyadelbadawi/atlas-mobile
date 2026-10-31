import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'academy.dart';

/// The current academy and the last few picked, on this phone only.
class AcademyStore {
  AcademyStore(this._prefs);

  final SharedPreferences _prefs;
  static const _currentKey = 'academy.current';
  static const _recentKey = 'academy.recent';
  static const maxRecent = 5;

  Academy? get current {
    final raw = _prefs.getString(_currentKey);
    if (raw == null) return null;
    try {
      return Academy.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  List<Academy> get recent {
    final raw = _prefs.getStringList(_recentKey) ?? const [];
    return [for (final s in raw) ?_tryDecode(s)];
  }

  Future<void> setCurrent(Academy academy) async {
    await _prefs.setString(_currentKey, jsonEncode(academy.toJson()));
    final list = [
      academy,
      ...recent.where((a) => a.host != academy.host),
    ].take(maxRecent);
    await _prefs.setStringList(_recentKey, [
      for (final a in list) jsonEncode(a.toJson()),
    ]);
  }

  Future<void> clearCurrent() => _prefs.remove(_currentKey);

  Future<void> removeRecent(Academy academy) =>
      _prefs.setStringList(_recentKey, [
        for (final a in recent.where((a) => a.host != academy.host))
          jsonEncode(a.toJson()),
      ]);

  /// Puts back a recent academy just removed, where it was (undo).
  Future<void> restoreRecent(Academy academy, int index) {
    final list = [...recent.where((a) => a.host != academy.host)];
    list.insert(index.clamp(0, list.length), academy);
    return _prefs.setStringList(_recentKey, [
      for (final a in list.take(maxRecent)) jsonEncode(a.toJson()),
    ]);
  }

  static Academy? _tryDecode(String s) {
    try {
      return Academy.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}
