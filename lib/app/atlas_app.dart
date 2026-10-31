import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../features/system/splash_overlay.dart';
import '../features/system/system_screens.dart';
import '../l10n/app_localizations.dart';
import 'deep_links.dart';
import 'providers.dart';
import 'push.dart';
import 'router.dart';

class AtlasApp extends ConsumerWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final academy = ref.watch(sessionProvider.select((s) => s.academy));
    final palette = academy == null
        ? AcademyPalette.atlas
        : AcademyPalette.fromHslString(academy.primaryColor);
    final router = ref.watch(routerProvider);
    final locale = settings.languageCode == null
        ? null
        : Locale(settings.languageCode!);

    final font = ref.watch(bodyFontProvider);
    ThemeData theme(Brightness b, Locale l) => buildAtlasTheme(
      palette: palette,
      brightness: b,
      languageCode: l.languageCode,
      bodyFamily: font.family,
      bodyFallback: font.fallback,
    );

    // Push taps and foreground messages, once the router exists.
    ref.watch(pushControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(pushControllerProvider.notifier).attachHandlers(),
    );

    // Academy links (App Links, QR): opened once the session allows.
    ref.listen(
      sessionProvider.select((s) => s.status),
      (_, _) => ref.read(deepLinkProvider.notifier).consume(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(deepLinkProvider.notifier).start(),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) =>
          device?.languageCode == 'ar'
          ? const Locale('ar')
          : const Locale('en'),
      themeMode: settings.themeMode,
      // The theme depends on the resolved language (Arabic line heights), so
      // it is built inside the builder where the locale is known.
      builder: (context, child) {
        final l = Localizations.localeOf(context);
        final dark = switch (settings.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        // Tablets: text a little larger, on top of the user's own size.
        final mq = MediaQuery.of(context);
        final tablet = mq.size.shortestSide >= 600;
        return MediaQuery(
          data: tablet
              ? mq.copyWith(
                  textScaler: _Times(mq.textScaler, AtlasSize.tabletTextScale),
                )
              : mq,
          child: Theme(
            data: theme(dark ? Brightness.dark : Brightness.light, l),
            child: ref.watch(splashEnabledProvider)
                ? SplashOverlay(
                    ready: ref.watch(
                      sessionProvider.select(
                        (s) => s.status != SessionStatus.restoring,
                      ),
                    ),
                    child: _SystemGate(child: child ?? const SizedBox()),
                  )
                : _SystemGate(child: child ?? const SizedBox()),
          ),
        );
      },
    );
  }
}

/// Minimum version and maintenance from `/public/mobile/config` (B5).
class _SystemGate extends ConsumerWidget {
  const _SystemGate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(mobileConfigProvider).value;
    final version = ref.watch(appVersionProvider).version;
    if (config == null) return child;
    if (config.maintenance) return const SystemGateScreen.maintenance();
    if (config.requiresUpdate(version)) {
      return SystemGateScreen.update(storeUrl: config.storeUrl);
    }
    return child;
  }
}

/// The user's text scaler, times [factor].
class _Times extends TextScaler {
  const _Times(this.base, this.factor);
  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _Times && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
