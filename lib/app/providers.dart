import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/academy/academy.dart';
import '../design/design.dart';
import '../core/academy/academy_directory.dart';
import '../core/academy/academy_store.dart';
import '../core/api/atlas_api_client.dart';
import '../core/api/secure_cookie_storage.dart';
import '../core/auth/auth_repository.dart';
import '../core/errors/error_catalog.dart';
import 'push.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPreferencesProvider'),
);
final errorCatalogProvider = Provider<ErrorCatalog>(
  (ref) => throw UnimplementedError('override errorCatalogProvider'),
);

/// `1.0.0 (1)`, from the platform's package info. Overridden in main().
final appVersionProvider = Provider<({String version, String build})>(
  (ref) => (version: '0.0.0', build: '0'),
);

/// Body face for the theme: Rubik (bundled, the web's body face), its
/// Arabic and Latin Extended subsets as fallbacks.
final bodyFontProvider = Provider<({String? family, List<String>? fallback})>(
  (ref) => (family: AtlasType.bodyFamily, fallback: AtlasType.bodyFallback),
);

/// The animated launch layer (off in screen tests, which start mid-app).
final splashEnabledProvider = Provider<bool>((ref) => true);

final cookieJarProvider = Provider<CookieJar>(
  (ref) => PersistCookieJar(storage: SecureCookieStorage()),
);

final academyDirectoryProvider = Provider((ref) => AcademyDirectory());

final academyStoreProvider = Provider(
  (ref) => AcademyStore(ref.watch(sharedPreferencesProvider)),
);

// ---------------------------------------------------------------- settings

@immutable
class AppSettings {
  const AppSettings({this.languageCode, this.themeMode = ThemeMode.system});

  /// null = follow the phone.
  final String? languageCode;
  final ThemeMode themeMode;
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _langKey = 'settings.language';
  static const _themeKey = 'settings.theme';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final theme = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppSettings(
      languageCode: prefs.getString(_langKey),
      themeMode: theme,
    );
  }

  Future<void> setLanguage(String? code) async {
    final prefs = ref.read(sharedPreferencesProvider);
    code == null
        ? await prefs.remove(_langKey)
        : await prefs.setString(_langKey, code);
    state = AppSettings(languageCode: code, themeMode: state.themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
    state = AppSettings(languageCode: state.languageCode, themeMode: mode);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

// ----------------------------------------------------------- mobile config

@immutable
class MobileConfig {
  const MobileConfig({
    this.minimumVersion = '0.0.0',
    this.storeUrl,
    this.maintenance = false,
    this.signInWithApple = false,
  });

  factory MobileConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MobileConfig();
    final platform = (Platform.isIOS ? json['ios'] : json['android']) as Map?;
    return MobileConfig(
      minimumVersion: platform?['minimumVersion'] as String? ?? '0.0.0',
      storeUrl: platform?['storeUrl'] as String?,
      maintenance: json['maintenance'] == true,
      signInWithApple: json['signInWithApple'] == true,
    );
  }

  final String minimumVersion;
  final String? storeUrl;
  final bool maintenance;
  final bool signInWithApple;

  /// True when [current] is below [minimumVersion] (dotted numbers).
  bool requiresUpdate(String current) {
    List<int> parts(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.split(RegExp(r'[^0-9]')).first) ?? 0)
        .toList();
    final a = parts(current), b = parts(minimumVersion);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }
}

final mobileConfigProvider = FutureProvider<MobileConfig>((ref) async {
  final json = await ref.watch(academyDirectoryProvider).mobileConfig();
  return MobileConfig.fromJson(json);
});

// ----------------------------------------------------------------- session

enum SessionStatus { noAcademy, restoring, signedOut, signedIn }

@immutable
class SessionState {
  const SessionState({required this.status, this.academy, this.user});

  final SessionStatus status;
  final Academy? academy;
  final Map<String, dynamic>? user;

  String get displayName => (user?['name'] as String?)?.trim() ?? '';
}

/// The chosen academy, its API client, and whether the learner is signed in
/// to it. One academy at a time; switching keeps each academy's cookies, so
/// coming back to an academy restores its session.
class SessionController extends Notifier<SessionState> {
  AtlasApiClient? _client;
  AuthRepository? _auth;

  AtlasApiClient? get client => _client;
  AuthRepository? get auth => _auth;

  @override
  SessionState build() {
    final academy = ref.read(academyStoreProvider).current;
    if (academy == null) {
      return const SessionState(status: SessionStatus.noAcademy);
    }
    _open(academy);
    Future.microtask(restore);
    return SessionState(status: SessionStatus.restoring, academy: academy);
  }

  void _open(Academy academy) {
    final version = ref.read(appVersionProvider);
    final os = Platform.isIOS
        ? 'iPhone; iOS ${Platform.operatingSystemVersion}'
        : Platform.isAndroid
        ? 'Android'
        : Platform.operatingSystem;
    _client = AtlasApiClient(
      endpoint: academy.endpoint,
      cookieJar: ref.read(cookieJarProvider),
      userAgent: 'AtlasApp/${version.version} ($os)',
      acceptLanguage: ref.read(appSettingsProvider).languageCode,
      onSessionLost: (_) {
        if (state.status == SessionStatus.signedIn) {
          state = SessionState(
            status: SessionStatus.signedOut,
            academy: state.academy,
          );
        }
      },
    );
    _auth = AuthRepository(_client!, academyId: academy.id);
  }

  Future<void> restore() async {
    final academy = state.academy;
    if (academy == null || _auth == null) return;
    try {
      final user = await _auth!.restore();
      if (state.academy != academy) return;
      state = SessionState(
        status: SessionStatus.signedIn,
        academy: academy,
        user: user,
      );
    } on Object {
      if (state.academy != academy) return;
      state = SessionState(status: SessionStatus.signedOut, academy: academy);
    }
  }

  Future<void> chooseAcademy(Academy academy) async {
    await ref.read(academyStoreProvider).setCurrent(academy);
    _open(academy);
    state = SessionState(status: SessionStatus.restoring, academy: academy);
    await restore();
  }

  Future<void> leaveAcademy() async {
    await ref.read(academyStoreProvider).clearCurrent();
    _client = null;
    _auth = null;
    state = const SessionState(status: SessionStatus.noAcademy);
  }

  void signedIn(Map<String, dynamic> user) {
    state = SessionState(
      status: SessionStatus.signedIn,
      academy: state.academy,
      user: user,
    );
  }

  Future<void> signOut() async {
    await ref.read(pushControllerProvider.notifier).unregister();
    try {
      await _auth?.signOut();
    } on Object {
      // Signed out locally either way; the cookie is cleared by the client.
    }
    state = SessionState(
      status: SessionStatus.signedOut,
      academy: state.academy,
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
