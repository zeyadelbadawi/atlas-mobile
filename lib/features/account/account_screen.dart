import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// The Account tab: who is signed in, devices, language, appearance,
/// policies, change academy, sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    String academy,
  ) async {
    final l = context.l10n;
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: Text(l.accountSignOutConfirm(academy)),
        actions: [
          _action(c, l.commonCancel, false),
          _action(c, l.accountSignOut, true, destructive: true),
        ],
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).signOut();
  }

  Widget _action(
    BuildContext c,
    String label,
    bool value, {
    bool destructive = false,
  }) => Theme.of(c).platform == TargetPlatform.iOS
      ? CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(c, value),
          child: Text(label),
        )
      : TextButton(
          onPressed: () => Navigator.pop(c, value),
          child: Text(label),
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(appSettingsProvider);
    final academy = session.academy!;
    final email = session.user?['email'] as String? ?? '';
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoverBand.home(
              academyName: academy.name,
              greeting: session.displayName.isEmpty
                  ? l.accountTitle
                  : session.displayName,
              logo: NetworkImage(academy.logoUrl.toString()),
              overlap: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      email,
                      textDirection: TextDirection.ltr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: a.type.subhead.copyWith(
                        color: a.colors.inkSecondary,
                      ),
                    ),
                    SectionHeader(title: l.accountLanguage),
                    _choice<String?>(
                      context,
                      settings.languageCode,
                      {
                        null: l.accountSystem,
                        'ar': l.accountArabic,
                        'en': l.accountEnglish,
                      },
                      (v) =>
                          ref.read(appSettingsProvider.notifier).setLanguage(v),
                    ),
                    SectionHeader(title: l.accountAppearance),
                    _choice<ThemeMode>(
                      context,
                      settings.themeMode,
                      {
                        ThemeMode.system: l.accountSystem,
                        ThemeMode.light: l.accountLight,
                        ThemeMode.dark: l.accountDark,
                      },
                      (v) => ref
                          .read(appSettingsProvider.notifier)
                          .setThemeMode(v),
                    ),
                    const SizedBox(height: AtlasSpace.s24),
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          title: l.accountLegal,
                          icon: LucideIcons.scrollText,
                          onTap: () => context.push('/legal'),
                        ),
                        SettingsRow(
                          title: l.accountAbout,
                          icon: LucideIcons.info,
                          onTap: () => context.push('/about'),
                        ),
                        SettingsRow(
                          title: l.accountChangeAcademy,
                          icon: LucideIcons.building2,
                          onTap: () =>
                              ref.read(sessionProvider.notifier).leaveAcademy(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AtlasSpace.s24),
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          title: l.accountSignOut,
                          icon: LucideIcons.logOut,
                          destructive: true,
                          onTap: () => _signOut(context, ref, academy.name),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice<T>(
    BuildContext context,
    T value,
    Map<T, String> options,
    ValueChanged<T> onChanged,
  ) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final e in options.entries)
            ButtonSegment<T>(value: e.key, label: Text(e.value)),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: context.atlas.colors.tonal,
          selectedForegroundColor: context.atlas.colors.accent,
        ),
      ),
    );
  }
}
