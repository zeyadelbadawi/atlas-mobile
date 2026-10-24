import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/atlas_app.dart';
import 'app/providers.dart';
import 'core/errors/error_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (prefs, errors, info) = await (
    SharedPreferences.getInstance(),
    ErrorCatalog.load(),
    PackageInfo.fromPlatform(),
  ).wait;
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        errorCatalogProvider.overrideWithValue(errors),
        appVersionProvider.overrideWithValue((
          version: info.version,
          build: info.buildNumber,
        )),
      ],
      child: const AtlasApp(),
    ),
  );
}
