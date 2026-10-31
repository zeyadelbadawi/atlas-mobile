import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens this app's page in the system settings, where the learner can
/// allow a permission they refused (the camera for QR codes). iOS takes the
/// `app-settings:` URL; Android goes through MainActivity. False when it
/// could not open.
Future<bool> openAppSettings({
  MethodChannel channel = const MethodChannel('atlas/app_settings'),
}) async {
  try {
    if (Platform.isIOS) {
      return await launchUrl(Uri.parse('app-settings:'));
    }
    return await channel.invokeMethod<bool>('open') ?? false;
  } on Object {
    return false;
  }
}
