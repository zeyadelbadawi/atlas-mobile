import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';
import '../certificates/certificates_screen.dart';
import '../legal/legal_screens.dart';
import '../results/results_screen.dart';
import 'account_settings_screens.dart';
import 'devices_screen.dart';

/// The Account tab: who is signed in, devices, language, appearance,
/// policies, change academy, sign out. On a wide screen (iPad) the page a
/// row opens sits beside the list instead of covering it.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

/// The page each row opens, for the side-by-side layout. Phones push the
/// same paths (router.dart).
Widget _page(String path) => switch (path) {
  '/account/results' => const ResultsScreen(),
  '/account/certificates' => const CertificatesScreen(),
  '/account/devices' => const DevicesScreen(),
  '/account/security' => const SecurityScreen(),
  '/account/notifications' => const NotificationSettingsScreen(),
  '/account/privacy' => const PrivacyScreen(),
  '/legal' => const LegalListScreen(),
  '/about' => const AboutScreen(),
  _ => const ProfileScreen(),
};

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String _open = '/account/profile';

  void _go(String path) =>
      isSplit(context) ? setState(() => _open = path) : context.push(path);

  SettingsRow _row(String title, IconData icon, String path) => SettingsRow(
    title: title,
    icon: icon,
    selected: isSplit(context) && _open == path,
    onTap: () => _go(path),
  );

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
  Widget build(BuildContext context) {
    final menu = _menu(context);
    if (!isSplit(context)) return menu;
    return SplitView(
      masterWidth: AtlasSize.masterWidth + 40,
      master: menu,
      detail: KeyedSubtree(key: ValueKey(_open), child: _page(_open)),
    );
  }

  Widget _menu(BuildContext context) {
    final l = context.l10n;
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
            _ProfileHeader(
              name: session.displayName.isEmpty
                  ? l.accountTitle
                  : session.displayName,
              email: email,
              academyName: academy.name,
              logo: NetworkImage(academy.logoUrl.toString()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AtlasSpace.gutter,
                0,
                AtlasSpace.gutter,
                AtlasSpace.gutter,
              ),
              child: ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: l.accountLearning),
                    SettingsGroup(
                      children: [
                        _row(
                          l.resultsTitle,
                          LucideIcons.chartColumn,
                          '/account/results',
                        ),
                        _row(
                          l.certificatesTitle,
                          LucideIcons.award,
                          '/account/certificates',
                        ),
                        _row(
                          l.accountDevices,
                          LucideIcons.smartphone,
                          '/account/devices',
                        ),
                      ],
                    ),
                    SectionHeader(title: l.accountSettings),
                    SettingsGroup(
                      children: [
                        _row(
                          l.accountProfile,
                          LucideIcons.userPen,
                          '/account/profile',
                        ),
                        _row(
                          l.accountSecurity,
                          LucideIcons.keyRound,
                          '/account/security',
                        ),
                        _row(
                          l.accountNotifications,
                          LucideIcons.bellRing,
                          '/account/notifications',
                        ),
                        _row(
                          l.accountPrivacy,
                          LucideIcons.shieldCheck,
                          '/account/privacy',
                        ),
                      ],
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
                        _row(l.accountLegal, LucideIcons.scrollText, '/legal'),
                        _row(l.accountAbout, LucideIcons.info, '/about'),
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

/// The learner on the academy's cover: their initials, name and email, and
/// the academy they are signed in to.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.academyName,
    this.logo,
  });

  final String name, email, academyName;
  final ImageProvider? logo;

  /// Two Latin initials ("ZE"); one Arabic letter, because two Arabic
  /// letters side by side read as a word.
  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(words.first)) {
      return words.first.characters.first;
    }
    return words.take(2).map((w) => w.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.onCover.computeLuminance() > 0.5
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Container(
        color: c.cover,
        padding: EdgeInsetsDirectional.fromSTEB(
          AtlasSpace.gutter,
          top + AtlasSpace.s16,
          AtlasSpace.gutter,
          AtlasSpace.s24,
        ),
        child: ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AcademyLogo(academyName: academyName, image: logo, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      academyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: a.type.footnote.copyWith(
                        color: c.onCover.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpace.s20),
              Entrance(
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.onCover,
                        ),
                        child: Text(
                          initials(name),
                          style: a.type.title2.copyWith(color: c.cover),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              name,
                              textDirection: contentDirection(context, name),
                              style: a.type.title1.copyWith(color: c.onCover),
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              textDirection: TextDirection.ltr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: a.type.subhead.copyWith(
                                color: c.onCover.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
