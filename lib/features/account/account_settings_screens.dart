import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/account/account_repository.dart';
import '../../core/api/api_error.dart';
import '../../design/design.dart';
import '../auth/register_screen.dart' show phonePrefix;
import '../learning/learning_ui.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  ref.watch(sessionProvider.select((s) => (s.academy, s.user?['id'])));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null) throw StateError('no academy session');
  return AccountRepository(client);
});

final _phoneProvider = FutureProvider.autoDispose<AccountPhone>(
  (ref) => ref.watch(accountRepositoryProvider).phone(),
);

final _sessionsProvider = FutureProvider.autoDispose<List<AccountSession>>(
  (ref) => ref.watch(accountRepositoryProvider).sessions(),
);

final _learningEmailsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(accountRepositoryProvider).learningEmails(),
);

final _privacyRequestsProvider =
    FutureProvider.autoDispose<List<PrivacyRequest>>(
      (ref) => ref.watch(accountRepositoryProvider).privacyRequests(),
    );

final _canDeleteProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(accountRepositoryProvider).canDeleteFromApp(),
);

void _toast(BuildContext context, String text) => ScaffoldMessenger.of(context)
    .showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );

/* ---------------------------------------------------------------- profile */

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final _name = TextEditingController(
    text: ref.read(sessionProvider).displayName,
  );
  final _phone = TextEditingController();
  bool _phoneSeeded = false, _savingName = false, _savingPhone = false;
  bool _verifySent = false;
  String? _nameError, _phoneError, _banner;

  /// What is saved now; Save stays off until the field differs from it.
  late String _savedName = _name.text.trim();
  String _savedPhone = '';

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _phone.addListener(_changed);
  }

  // Not while the saved phone is filled in during build.
  bool _seeding = false;
  void _changed() {
    if (!_seeding) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final l = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.profileNameRequired);
      return;
    }
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      final me = await ref.read(accountRepositoryProvider).updateName(name);
      ref.read(sessionProvider.notifier).signedIn(me.raw);
      _savedName = name;
      if (mounted) _toast(context, l.profileSaved);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _nameError = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePhone() async {
    final l = context.l10n;
    final n = _phone.text.trim();
    if (n.isEmpty) {
      setState(() => _phoneError = l.validationPhoneRequired);
      return;
    }
    setState(() {
      _savingPhone = true;
      _phoneError = null;
    });
    try {
      await ref.read(accountRepositoryProvider).setPhone(n, 'EG');
      ref.invalidate(_phoneProvider);
      _savedPhone = _phone.text.trim();
      if (mounted) _toast(context, l.profileSaved);
    } on AtlasApiException catch (e) {
      if (mounted) {
        setState(
          () => _phoneError = e.fields['phoneNumber'] != null
              ? ref
                    .read(errorCatalogProvider)
                    .message(e.fields['phoneNumber']!, context.languageCode)
              : errorText(ref, context, e),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhone = false);
    }
  }

  Future<void> _verify() async {
    try {
      await ref.read(accountRepositoryProvider).resendEmailVerification();
      if (mounted) setState(() => _verifySent = true);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _banner = errorText(ref, context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final email = ref.watch(sessionProvider).user?['email'] as String? ?? '';
    final phone = ref.watch(_phoneProvider);
    if (!_phoneSeeded && phone.hasValue) {
      _phoneSeeded = true;
      _seeding = true;
      _phone.text = _savedPhone =
          phone.value!.nationalNumber?.replaceFirst(RegExp(r'^0?'), '0') ?? '';
      _seeding = false;
    }
    return FormScreen(
      title: l.accountProfile,
      icon: LucideIcons.userPen,
      children: [
        if (_banner != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _banner!),
          const SizedBox(height: AtlasSpace.s16),
        ],
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasTextField(
                label: l.profileName,
                hint: l.profileNameHint,
                controller: _name,
                error: _nameError,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: AtlasSpace.s12),
              AtlasButton(
                label: l.profileSave,
                style: AtlasButtonStyle.tonal,
                loading: _savingName,
                onPressed: _savingName || _name.text.trim() == _savedName
                    ? null
                    : _saveName,
              ),
            ],
          ),
        ),
        SectionHeader(title: l.profileEmail),
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                email,
                textDirection: TextDirection.ltr,
                textAlign: Directionality.of(context) == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
                style: a.type.body.copyWith(color: c.ink),
              ),
              const SizedBox(height: 4),
              Text(
                l.profileEmailNote,
                style: a.type.footnote.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 8),
              if (_verifySent)
                AtlasBanner(
                  kind: AtlasBannerKind.success,
                  message: l.profileVerifySent(email),
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _verify,
                    child: Text(l.profileVerifyEmail),
                  ),
                ),
            ],
          ),
        ),
        SectionHeader(title: l.profilePhone),
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasTextField(
                label: l.profilePhone,
                controller: _phone,
                ltrValue: true,
                prefix: phonePrefix(context),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.telephoneNumberNational],
                error: _phoneError,
                helper: l.registerPhoneHint,
              ),
              const SizedBox(height: AtlasSpace.s12),
              AtlasButton(
                label: l.profileSave,
                style: AtlasButtonStyle.tonal,
                loading: _savingPhone,
                onPressed: _savingPhone || _phone.text.trim() == _savedPhone
                    ? null
                    : _savePhone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* --------------------------------------------------------------- security */

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _currentError, _nextError, _confirmError;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _change() async {
    final l = context.l10n;
    setState(() {
      _currentError = _current.text.isEmpty ? l.securityCurrentRequired : null;
      _nextError = _next.text.length < 8 ? l.securityPasswordTooShort : null;
      _confirmError = _confirm.text != _next.text
          ? l.securityPasswordMismatch
          : null;
    });
    if (_currentError != null || _nextError != null || _confirmError != null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .changePassword(_current.text, _next.text);
      if (!mounted) return;
      // The server has ended every session, this one included.
      await showAdaptiveDialog<void>(
        context: context,
        builder: (c) => AlertDialog.adaptive(
          title: Text(l.securityPasswordChangedTitle),
          content: Text(l.securityPasswordChangedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(l.commonContinue),
            ),
          ],
        ),
      );
      await ref.read(sessionProvider.notifier).signOut();
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.messageKey == 'errors.auth.invalidCurrentPassword') {
          _currentError = errorText(ref, context, e);
        } else {
          _nextError = errorText(ref, context, e);
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revoke(AccountSession s) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.securitySignOutSessionConfirm(
        context.deviceLabel(s.deviceLabel),
      ),
      confirm: l.securitySignOutSession,
      cancel: l.commonCancel,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(accountRepositoryProvider).revokeSession(s.id);
    } on AtlasApiException catch (e) {
      if (mounted) _toast(context, errorText(ref, context, e));
    }
    ref.invalidate(_sessionsProvider);
  }

  Future<void> _revokeOthers() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.securitySignOutOthersConfirm,
      confirm: l.securitySignOutSession,
      cancel: l.commonCancel,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(accountRepositoryProvider).revokeOtherSessions();
    } on AtlasApiException catch (e) {
      if (mounted) _toast(context, errorText(ref, context, e));
    }
    ref.invalidate(_sessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final sessions = ref.watch(_sessionsProvider);
    return FormScreen(
      title: l.securityTitle,
      icon: LucideIcons.keyRound,
      children: [
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.securityChangePassword,
                style: a.type.title3.copyWith(color: c.ink),
              ),
              const SizedBox(height: AtlasSpace.s12),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtlasTextField(
                      label: l.securityCurrentPassword,
                      controller: _current,
                      password: true,
                      ltrValue: true,
                      error: _currentError,
                      autofillHints: const [AutofillHints.password],
                      showPasswordLabel: l.showPassword,
                      hidePasswordLabel: l.hidePassword,
                    ),
                    const SizedBox(height: AtlasSpace.s12),
                    AtlasTextField(
                      label: l.securityNewPassword,
                      controller: _next,
                      password: true,
                      ltrValue: true,
                      helper: l.securityPasswordRule,
                      error: _nextError,
                      autofillHints: const [AutofillHints.newPassword],
                      showPasswordLabel: l.showPassword,
                      hidePasswordLabel: l.hidePassword,
                    ),
                    const SizedBox(height: AtlasSpace.s12),
                    AtlasTextField(
                      label: l.securityConfirmPassword,
                      controller: _confirm,
                      password: true,
                      ltrValue: true,
                      error: _confirmError,
                      autofillHints: const [AutofillHints.newPassword],
                      showPasswordLabel: l.showPassword,
                      hidePasswordLabel: l.hidePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasButton(
                label: l.securityChangePassword,
                loading: _saving,
                onPressed: _saving ? null : _change,
              ),
            ],
          ),
        ),
        SectionHeader(title: l.securitySessions),
        AsyncBody<List<AccountSession>>(
          value: sessions,
          onRetry: () => ref.invalidate(_sessionsProvider),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                children: [
                  for (final s in list)
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        8,
                        12,
                      ),
                      child: Row(
                        children: [
                          const IconTile(icon: LucideIcons.monitorSmartphone),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.isCurrent
                                      ? l.securityThisDevice
                                      : context.deviceLabel(s.deviceLabel),
                                  style: a.type.headline.copyWith(color: c.ink),
                                ),
                                if (s.lastUsedAt != null)
                                  Text(
                                    l.securityLastActive(
                                      relative(context, s.lastUsedAt!),
                                    ),
                                    style: a.type.footnote.copyWith(
                                      color: c.inkSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!s.isCurrent)
                            TextButton(
                              onPressed: () => _revoke(s),
                              child: Text(l.securitySignOutSession),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (list.where((s) => !s.isCurrent).length > 1) ...[
                const SizedBox(height: AtlasSpace.s12),
                AtlasButton(
                  label: l.securitySignOutOthers,
                  style: AtlasButtonStyle.destructive,
                  onPressed: _revokeOthers,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/* ---------------------------------------------------------- notifications */

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final push = ref.watch(pushControllerProvider);
    final emails = ref.watch(_learningEmailsProvider);
    return FormScreen(
      title: l.notificationSettingsTitle,
      icon: LucideIcons.bellRing,
      children: [
        if (push != PushStatus.unavailable) ...[
          SettingsGroup(
            children: [
              SettingsRow(
                title: l.notificationSettingsPush,
                icon: LucideIcons.bellRing,
                value: push == PushStatus.granted
                    ? l.notificationSettingsPushOn
                    : l.notificationSettingsPushOff,
                showChevron: push == PushStatus.notAsked,
                onTap: push == PushStatus.notAsked
                    ? () => ref
                          .read(pushControllerProvider.notifier)
                          .requestPermission()
                    : null,
              ),
            ],
          ),
          if (push == PushStatus.denied) ...[
            const SizedBox(height: 8),
            Text(
              l.pushDenied,
              style: a.type.footnote.copyWith(color: c.inkSecondary),
            ),
          ],
          const SizedBox(height: AtlasSpace.s24),
        ],
        AsyncBody<bool>(
          value: emails,
          onRetry: () => ref.invalidate(_learningEmailsProvider),
          data: (on) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.notificationSettingsEmail,
                  style: a.type.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l.notificationSettingsEmailHelp,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
                value: on,
                onChanged: (v) async {
                  try {
                    await ref
                        .read(accountRepositoryProvider)
                        .setLearningEmails(v);
                  } on AtlasApiException catch (e) {
                    if (context.mounted) {
                      _toast(context, errorText(ref, context, e));
                    }
                  }
                  ref.invalidate(_learningEmailsProvider);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ---------------------------------------------------------------- privacy */

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busyExport = false, _busyDelete = false, _unverified = false;
  bool _verifySent = false;
  String? _error;

  late bool _analytics = ref.read(analyticsProvider).enabled;

  /// Asks for the emailed 6-digit code. Null when cancelled.
  Future<String?> _askCode(EmailChallenge c) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CodeSheet(maskedEmail: c.maskedEmail),
  );

  bool _handleEmailError(AtlasApiException e) {
    if (e.messageKey == 'errors.account.deletionEmailUnverified') {
      setState(() => _unverified = true);
      return true;
    }
    return false;
  }

  Future<void> _export() async {
    setState(() {
      _busyExport = true;
      _error = null;
    });
    try {
      final repo = ref.read(accountRepositoryProvider);
      final challenge = await repo.requestPrivacyCode();
      final code = await _askCode(challenge);
      if (code == null) return;
      await repo.fileExport(challenge, code);
      ref.invalidate(_privacyRequestsProvider);
    } on AtlasApiException catch (e) {
      if (!mounted || _handleEmailError(e)) return;
      setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busyExport = false);
    }
  }

  Future<void> _download(PrivacyRequest r) async {
    try {
      final bundle = await ref
          .read(accountRepositoryProvider)
          .downloadExport(r.id);
      if (!mounted) return;
      await shareJsonFile(context, 'atlas-data-export.json', bundle);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (_) => const _DeleteConfirmDialog(),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busyDelete = true;
      _error = null;
    });
    try {
      final repo = ref.read(accountRepositoryProvider);
      final challenge = await repo.requestDeletionCode();
      final code = await _askCode(challenge);
      if (code == null) return;
      await repo.deleteAccount(challenge, code);
      ref.read(analyticsProvider).event('account_deleted');
      // The account is gone: forget its email on every academy.
      final prefs = ref.read(sharedPreferencesProvider);
      for (final k in prefs.getKeys().where(
        (k) => k.startsWith(lastEmailKey('')),
      )) {
        await prefs.remove(k);
      }
      if (mounted) _toast(context, l.deleteDone);
      await ref.read(sessionProvider.notifier).signOut();
    } on AtlasApiException catch (e) {
      if (!mounted || _handleEmailError(e)) return;
      setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busyDelete = false);
    }
  }

  Future<void> _verify() async {
    try {
      await ref.read(accountRepositoryProvider).resendEmailVerification();
      if (mounted) setState(() => _verifySent = true);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final email = ref.watch(sessionProvider).user?['email'] as String? ?? '';
    final requests = ref.watch(_privacyRequestsProvider);
    final canDelete = ref.watch(_canDeleteProvider);
    final firebase = ref.watch(firebaseReadyProvider);
    return FormScreen(
      title: l.privacyTitle,
      icon: LucideIcons.shieldCheck,
      children: [
        if (_error != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
          const SizedBox(height: AtlasSpace.s16),
        ],
        if (_unverified) ...[
          AtlasBanner(message: l.privacyNeedsVerifiedEmail),
          const SizedBox(height: 8),
          if (_verifySent)
            AtlasBanner(
              kind: AtlasBannerKind.success,
              message: l.profileVerifySent(email),
            )
          else
            AtlasButton(
              label: l.profileVerifyEmail,
              style: AtlasButtonStyle.tonal,
              onPressed: _verify,
            ),
          const SizedBox(height: AtlasSpace.s16),
        ],
        if (firebase)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.privacyAnalytics,
              style: a.type.body.copyWith(color: c.ink),
            ),
            subtitle: Text(
              l.privacyAnalyticsHelp,
              style: a.type.footnote.copyWith(color: c.inkSecondary),
            ),
            value: _analytics,
            onChanged: (v) async {
              setState(() => _analytics = v);
              await ref.read(analyticsProvider).setEnabled(v);
            },
          ),
        SectionHeader(title: l.privacyExport),
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.privacyExportHelp,
                style: a.type.subhead.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 8),
              AsyncBody<List<PrivacyRequest>>(
                value: requests,
                onRetry: () => ref.invalidate(_privacyRequestsProvider),
                data: (list) {
                  final exports = list
                      .where((r) => r.type == 'export')
                      .toList();
                  final latest = exports.firstOrNull;
                  final open =
                      latest != null &&
                      latest.status != 'completed' &&
                      latest.status != 'rejected';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (latest != null && latest.canDownload) ...[
                        Text(
                          l.privacyExportReady(
                            latest.exportAvailableUntil == null
                                ? ''
                                : shortDate(
                                    context,
                                    latest.exportAvailableUntil!,
                                  ),
                          ),
                          style: a.type.subhead.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: 8),
                        AtlasButton(
                          label: l.privacyExportDownload,
                          icon: LucideIcons.download,
                          onPressed: () => _download(latest),
                        ),
                      ] else if (open)
                        Text(
                          l.privacyExportRequested(
                            latest.createdAt == null
                                ? ''
                                : shortDate(context, latest.createdAt!),
                          ),
                          style: a.type.subhead.copyWith(color: c.ink),
                        )
                      else
                        AtlasButton(
                          label: l.privacyExport,
                          style: AtlasButtonStyle.tonal,
                          icon: LucideIcons.fileDown,
                          loading: _busyExport,
                          onPressed: _busyExport ? null : _export,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SectionHeader(title: l.privacyDeleteAccount),
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.privacyDeleteHelp,
                style: a.type.subhead.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 8),
              AsyncBody<bool>(
                value: canDelete,
                onRetry: () => ref.invalidate(_canDeleteProvider),
                data: (allowed) => allowed
                    ? AtlasButton(
                        label: l.privacyDeleteAccount,
                        style: AtlasButtonStyle.destructive,
                        icon: LucideIcons.trash2,
                        loading: _busyDelete,
                        onPressed: _busyDelete ? null : _delete,
                      )
                    : AtlasBanner(message: l.privacyDeleteNotAllowed),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ok = _typed.text.trim().toUpperCase() == 'DELETE';
    return AlertDialog(
      title: Text(l.deleteConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deleteConfirmBody),
          const SizedBox(height: 12),
          TextField(
            controller: _typed,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.deleteConfirmType),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: context.atlas.colors.danger,
          ),
          onPressed: ok ? () => Navigator.pop(context, true) : null,
          child: Text(l.deleteConfirmAction),
        ),
      ],
    );
  }
}

class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.maskedEmail});
  final String maskedEmail;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        0,
        AtlasSpace.gutter,
        AtlasSpace.s24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.privacyCodeTitle,
            style: a.type.title3.copyWith(color: a.colors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l.privacyCodeBody(widget.maskedEmail),
            style: a.type.subhead.copyWith(color: a.colors.inkSecondary),
          ),
          const SizedBox(height: AtlasSpace.s16),
          CodeInput(
            controller: _code,
            onCompleted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: AtlasSpace.s16),
          AtlasButton(
            label: l.privacyCodeContinue,
            onPressed: () {
              if (_code.text.length == 6) Navigator.pop(context, _code.text);
            },
          ),
        ],
      ),
    );
  }
}

/// Writes [data] as a JSON file and opens the share sheet (save to Files,
/// Drive, email...).
Future<void> shareJsonFile(
  BuildContext context,
  String name,
  Object? data,
) async {
  final bytes = Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
  );
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json', name: name)],
      fileNameOverrides: [name],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
