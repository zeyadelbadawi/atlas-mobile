import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/atlas_analytics.dart';
import '../core/notifications/notification_catalog.dart';
import '../core/notifications/notifications_repository.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'web_paths.dart';

/// True when Firebase initialised (a build with google-services.json on
/// Android / GoogleService-Info.plist on iOS). Overridden in main().
final firebaseReadyProvider = Provider<bool>((ref) => false);

final analyticsProvider = Provider<AtlasAnalytics>(
  (ref) => AtlasAnalytics(
    available: ref.watch(firebaseReadyProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);

/// Overridden in main() with the loaded catalogue.
final notificationCatalogProvider = Provider<NotificationCatalog>(
  (ref) => NotificationCatalog(const {'en': {}, 'ar': {}}),
);

/// For in-app messages (a push that arrives while the app is open).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  ref.watch(sessionProvider.select((s) => (s.academy, s.user?['id'])));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null) throw StateError('no academy session');
  return NotificationsRepository(client);
});

final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).unreadCount(),
);

final announcementsProvider = FutureProvider.autoDispose<List<Announcement>>(
  (ref) => ref.watch(notificationsRepositoryProvider).announcements(),
);

/// The notification feed, page by page.
class NotificationFeed extends AsyncNotifier<NotificationPageState> {
  @override
  Future<NotificationPageState> build() async {
    final first = await ref.watch(notificationsRepositoryProvider).list();
    return NotificationPageState(first.items, page: 1, hasMore: first.hasMore);
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || !s.hasMore || s.loadingMore) return;
    state = AsyncData(s.copy(loadingMore: true));
    try {
      final next = await ref
          .read(notificationsRepositoryProvider)
          .list(page: s.page + 1);
      state = AsyncData(
        NotificationPageState(
          [...s.items, ...next.items],
          page: s.page + 1,
          hasMore: next.hasMore,
        ),
      );
    } on Object {
      state = AsyncData(s.copy(loadingMore: false));
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    final s = state.value;
    if (s != null) {
      state = AsyncData(
        s.copy(items: [for (final x in s.items) x.id == n.id ? x.read() : x]),
      );
    }
    try {
      await ref.read(notificationsRepositoryProvider).markRead(n.id);
    } on Object {
      // The badge recounts from the server either way.
    }
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    final s = state.value;
    if (s != null) {
      state = AsyncData(s.copy(items: [for (final x in s.items) x.read()]));
    }
    await ref.read(notificationsRepositoryProvider).markAllRead();
    ref.invalidate(unreadCountProvider);
  }
}

class NotificationPageState {
  NotificationPageState(
    this.items, {
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });
  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  NotificationPageState copy({
    List<AppNotification>? items,
    bool? loadingMore,
  }) => NotificationPageState(
    items ?? this.items,
    page: page,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final notificationFeedProvider =
    AsyncNotifierProvider.autoDispose<NotificationFeed, NotificationPageState>(
      NotificationFeed.new,
    );

/* ------------------------------------------------------------------ push */

enum PushStatus {
  /// No Firebase in this build: the app works, without push.
  unavailable,

  /// Not asked yet: the app explains first, then asks (never at launch).
  notAsked,
  granted,

  /// Refused: only the phone's Settings can turn it back on.
  denied,
}

/// Push for the signed-in academy session: asks permission when the
/// learner chooses to, registers this phone with the backend (B1), routes a
/// tapped notification to its screen, and shows one that arrives while the
/// app is open as an in-app message.
class PushController extends Notifier<PushStatus> {
  static const _deviceKey = 'push.device.';
  bool _handlersAttached = false;

  @override
  PushStatus build() {
    if (!ref.watch(firebaseReadyProvider)) return PushStatus.unavailable;
    ref.listen(sessionProvider.select((s) => s.status), (_, status) {
      if (status == SessionStatus.signedIn) unawaited(_syncIfGranted());
    }, fireImmediately: true);
    unawaited(_readStatus());
    return PushStatus.notAsked;
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  bool get _ready => ref.read(firebaseReadyProvider);

  Future<void> _readStatus() async {
    if (!_ready) return;
    try {
      final s = await _fm.getNotificationSettings();
      state = _map(s.authorizationStatus);
    } on Object catch (e) {
      debugPrint('push status: $e');
    }
  }

  PushStatus _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushStatus.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushStatus.denied,
    AuthorizationStatus.notDetermined => PushStatus.notAsked,
  };

  /// The learner tapped "Turn on notifications".
  Future<PushStatus> requestPermission() async {
    if (!_ready) return state;
    try {
      final s = await _fm.requestPermission();
      state = _map(s.authorizationStatus);
      ref.read(analyticsProvider).event('push_permission', {
        'granted': state == PushStatus.granted ? 1 : 0,
      });
      if (state == PushStatus.granted) await _register();
    } on Object catch (e) {
      debugPrint('push permission: $e');
    }
    return state;
  }

  Future<void> _syncIfGranted() async {
    await _readStatus();
    if (state == PushStatus.granted) await _register();
  }

  String? _deviceKeyFor() {
    final s = ref.read(sessionProvider);
    final user = s.user?['id'];
    return s.academy == null || user == null
        ? null
        : '$_deviceKey${s.academy!.id}.$user';
  }

  Future<void> _register([String? token]) async {
    final session = ref.read(sessionProvider);
    final key = _deviceKeyFor();
    if (!_ready || session.status != SessionStatus.signedIn || key == null) {
      return;
    }
    try {
      // The backend (B1) sends with FCM HTTP v1 `message.token`, i.e. the
      // registration token. firebase_messaging 17 deprecates it for the
      // installation-id (FID) API; move with the backend, not before.
      // ignore: deprecated_member_use
      final t = token ?? await _fm.getToken();
      if (t == null) return;
      final settings = ref.read(appSettingsProvider);
      final lang =
          settings.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final id = await ref
          .read(notificationsRepositoryProvider)
          .registerPushDevice(
            token: t,
            platform: Platform.isIOS ? 'ios' : 'android',
            appVersion: ref.read(appVersionProvider).version,
            locale: lang == 'ar' ? 'ar' : 'en',
          );
      if (id != null) {
        await ref.read(sharedPreferencesProvider).setString(key, id);
      }
    } on Object catch (e) {
      debugPrint('push register: $e');
    }
  }

  /// Before signing out: this phone stops receiving this account's pushes.
  Future<void> unregister() async {
    final key = _deviceKeyFor();
    if (key == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final id = prefs.getString(key);
    if (id == null) return;
    try {
      await ref.read(notificationsRepositoryProvider).removePushDevice(id);
    } on Object {
      // The server also stops sending once the session is revoked.
    }
    await prefs.remove(key);
  }

  /// Once, after the router exists: taps, foreground messages, token
  /// rotation.
  Future<void> attachHandlers() async {
    if (!_ready || _handlersAttached) return;
    _handlersAttached = true;
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    FirebaseMessaging.onMessage.listen(_foreground);
    // ignore: deprecated_member_use
    _fm.onTokenRefresh.listen((t) => unawaited(_register(t)));
    final initial = await _fm.getInitialMessage();
    if (initial != null) _open(initial);
  }

  void _open(RemoteMessage m) {
    ref.read(analyticsProvider).event('notification_open', {'source': 'push'});
    final path = appPathForWebLink(m.data['path'] as String?);
    ref.invalidate(notificationFeedProvider);
    ref.invalidate(unreadCountProvider);
    unawaited(_goWhenSignedIn(path));
  }

  Future<void> _goWhenSignedIn(String path) async {
    for (var i = 0; i < 20; i++) {
      if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
        ref.read(routerProvider).push(path);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  void _foreground(RemoteMessage m) {
    ref.invalidate(notificationFeedProvider);
    ref.invalidate(unreadCountProvider);
    final n = m.notification;
    if (n == null) return;
    final messenger = scaffoldMessengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text([n.title, n.body].whereType<String>().join('\n')),
        action: SnackBarAction(
          label: messenger.mounted
              ? AppLocalizations.of(messenger.context).notificationOpen
              : 'Open',
          onPressed: () => _open(m),
        ),
      ),
    );
  }
}

final pushControllerProvider = NotifierProvider<PushController, PushStatus>(
  PushController.new,
);
