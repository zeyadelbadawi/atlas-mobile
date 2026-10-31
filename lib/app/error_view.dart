import 'package:flutter/material.dart';

/// What a learner sees, in a release build, where part of a screen failed
/// to draw: a calm note instead of Flutter's blank grey box. Developers
/// keep the red error screen in debug builds.
Widget releaseErrorWidget(FlutterErrorDetails details) => Builder(
  builder: (context) {
    final ar = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final fg = dark ? const Color(0xFFB4BAC8) : const Color(0xFF5C657A);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        color: dark ? const Color(0xFF161B27) : const Color(0xFFF1F3F7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: fg, size: 28),
            const SizedBox(height: 8),
            Text(
              ar ? 'تعذّر عرض هذا الجزء. ارجع وافتح الصفحة مرة أخرى.' : "This part couldn't be shown. Go back and open the page again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  },
);
