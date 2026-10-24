import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the cookie jar in the platform keystore (Keychain / Android
/// Keystore-backed encrypted prefs) instead of plain files.
///
/// The jar holds the session's refresh token (`__Host-atlas_session`), the
/// learning-device id (`atlas_device`) and the trusted-device mark
/// (`atlas_trust`). They must survive an app restart, and nothing else on
/// the phone should be able to read them.
class SecureCookieStorage implements Storage {
  SecureCookieStorage({
    FlutterSecureStorage? storage,
    this.prefix = 'atlas.cookies.',
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String prefix;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: '$prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: '$prefix$key', value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: '$prefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}

/// In-memory [Storage] for tests.
class MemoryCookieStorage implements Storage {
  final Map<String, String> values = {};

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}
