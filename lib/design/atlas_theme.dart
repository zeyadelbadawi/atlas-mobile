import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens/academy_palette.dart';
import 'tokens/atlas_colors.dart';
import 'tokens/atlas_type.dart';

export 'tokens/academy_palette.dart';
export 'tokens/atlas_colors.dart';
export 'tokens/atlas_metrics.dart';
export 'tokens/atlas_type.dart';

/// Builds the app theme for one academy, brightness and language. Platform
/// widgets (dialogs, sheets, switches, snackbars, selection) read the
/// Material/Cupertino themes; Atlas widgets read [AtlasColors] and
/// [AtlasType] through `context.atlas`.
ThemeData buildAtlasTheme({
  required AcademyPalette palette,
  required Brightness brightness,
  required String languageCode,
  String? bodyFamily,
  List<String>? bodyFallback,
  TargetPlatform? platform,
}) {
  final c = AtlasColors.of(palette, brightness);
  final t = AtlasType.forLanguage(
    languageCode,
    bodyFamily: bodyFamily,
    bodyFallback: bodyFallback,
  );
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.button,
    onPrimary: c.onButton,
    primaryContainer: c.tonal,
    onPrimaryContainer: c.accent,
    secondary: c.accent,
    onSecondary: c.raised,
    secondaryContainer: c.tonal,
    onSecondaryContainer: c.ink,
    tertiary: c.cover,
    onTertiary: c.onCover,
    error: c.danger,
    onError: c.raised,
    surface: c.paper,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSecondary,
    surfaceContainerLowest: c.raised,
    surfaceContainerLow: c.raised,
    surfaceContainer: c.raised,
    surfaceContainerHigh: c.sunken,
    surfaceContainerHighest: c.sunken,
    outline: c.ruleStrong,
    outlineVariant: c.rule,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: c.ink,
    onInverseSurface: c.paper,
    inversePrimary: c.tonal,
  );
  final textTheme = TextTheme(
    displayLarge: t.largeTitle,
    displayMedium: t.title1,
    displaySmall: t.title2,
    headlineLarge: t.title1,
    headlineMedium: t.title2,
    headlineSmall: t.title3,
    titleLarge: t.title3,
    titleMedium: t.headline,
    titleSmall: t.subhead,
    bodyLarge: t.body,
    bodyMedium: t.callout,
    bodySmall: t.footnote,
    labelLarge: t.button,
    labelMedium: t.caption,
    labelSmall: t.tab,
  ).apply(bodyColor: c.ink, displayColor: c.ink);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: platform,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.paper,
    canvasColor: c.paper,
    dividerColor: c.rule,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    fontFamily: bodyFamily,
    textTheme: textTheme,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.25),
      selectionHandleColor: c.accent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: t.headline.copyWith(color: c.ink),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: t.subhead.copyWith(color: c.paper),
      actionTextColor: c.tonal,
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.raised),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.raised,
      showDragHandle: true,
      dragHandleColor: c.ruleStrong,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.raised),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.button : c.ruleStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: c.accent,
      scaffoldBackgroundColor: c.paper,
      barBackgroundColor: c.paper,
    ),
    extensions: [c, t],
  );
}

/// `context.atlas.colors.accent`, `context.atlas.type.title2`.
class AtlasThemeAccess {
  const AtlasThemeAccess(this.colors, this.type);
  final AtlasColors colors;
  final AtlasType type;
}

extension AtlasThemeContext on BuildContext {
  AtlasThemeAccess get atlas {
    final theme = Theme.of(this);
    return AtlasThemeAccess(
      theme.extension<AtlasColors>()!,
      theme.extension<AtlasType>()!,
    );
  }
}
