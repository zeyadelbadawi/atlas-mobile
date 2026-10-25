import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/atlas_app.dart';
import 'app/providers.dart';
import 'app/push.dart';
import 'core/errors/error_catalog.dart';
import 'core/firebase/atlas_analytics.dart';
import 'core/notifications/notification_catalog.dart';

/// Firebase is optional at runtime: a build without its config file (an iOS
/// build before the Apple account exists) runs without push and Analytics.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (e) {
    debugPrint('firebase unavailable: $e');
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (prefs, errors, notifications, info, firebase) = await (
    SharedPreferences.getInstance(),
    ErrorCatalog.load(),
    NotificationCatalog.load(),
    PackageInfo.fromPlatform(),
    _initFirebase(),
  ).wait;
  await AtlasAnalytics(available: firebase, prefs: prefs).applyStoredChoice();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        errorCatalogProvider.overrideWithValue(errors),
        notificationCatalogProvider.overrideWithValue(notifications),
        firebaseReadyProvider.overrideWithValue(firebase),
        appVersionProvider.overrideWithValue((
          version: info.version,
          build: info.buildNumber,
        )),
      ],
      child: const AtlasApp(),
    ),
  );
}
