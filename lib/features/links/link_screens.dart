import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../design/design.dart';
import '../auth/sign_in_flow.dart';

/// `/verify-email?token=…` opened in the app. The link completes only for
/// the account it was sent to, so this screen is reached signed in; the
/// token is submitted once and never shown.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});
  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _VerifyState { working, done, invalid, failed }

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  _VerifyState _state = _VerifyState.working;
  String? _message;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return setState(() => _state = _VerifyState.invalid);
    }
    setState(() {
      _state = _VerifyState.working;
      _message = null;
    });
    try {
      await authOf(ref).verifyEmail(token);
      if (mounted) setState(() => _state = _VerifyState.done);
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      final retryable = e.retryable || e.status == null || e.status == 429;
      setState(() {
        if (e.messageKey == 'errors.auth.verificationTokenUsed') {
          // Already used: the address is verified.
          _state = _VerifyState.done;
        } else if (retryable) {
          _state = _VerifyState.failed;
          _message = errorText(ref, context, e);
        } else {
          _state = _VerifyState.invalid;
          _message = e.messageKey == 'errors.auth.invalidVerificationToken'
              ? null
              : errorText(ref, context, e);
        }
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _state = _VerifyState.failed;
          _message = errorText(ref, context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return FormScreen(
      title: l.verifyTitle,
      children: [
        switch (_state) {
          _VerifyState.working => Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AtlasSpace.s12),
              Expanded(
                child: Text(
                  l.verifyWorking,
                  style: a.type.body.copyWith(color: a.colors.inkSecondary),
                ),
              ),
            ],
          ),
          _VerifyState.done => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(LucideIcons.badgeCheck, size: 40, color: a.colors.accent),
              const SizedBox(height: AtlasSpace.s12),
              Text(
                l.verifyDone,
                style: a.type.title3.copyWith(color: a.colors.ink),
              ),
              const SizedBox(height: AtlasSpace.s20),
              AtlasButton(label: l.commonDone, onPressed: () => context.pop()),
            ],
          ),
          _VerifyState.invalid => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasBanner(
                kind: AtlasBannerKind.error,
                message: _message ?? l.verifyInvalid,
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasButton(
                label: l.verifyOpenProfile,
                style: AtlasButtonStyle.tonal,
                onPressed: () => context.pushReplacement('/account/profile'),
              ),
            ],
          ),
          _VerifyState.failed => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasBanner(
                kind: AtlasBannerKind.error,
                message: _message ?? l.loadFailed,
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasButton(
                label: l.commonRetry,
                style: AtlasButtonStyle.tonal,
                onPressed: _submit,
              ),
            ],
          ),
        },
      ],
    );
  }
}

/// `/reset-password?token=…` opened in the app: the link is checked first,
/// then a new password is set. The server ends every session afterwards,
/// so the learner signs in again with the new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool? _valid;
  bool _busy = false;
  String? _nextError, _confirmError, _banner;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return setState(() => _valid = false);
    }
    setState(() {
      _valid = null;
      _banner = null;
    });
    try {
      final ok = await authOf(ref).validateResetToken(token);
      if (mounted) setState(() => _valid = ok);
    } on Object catch (e) {
      if (mounted) setState(() => _banner = errorText(ref, context, e));
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _nextError = _next.text.length < 8 ? l.securityPasswordTooShort : null;
      _confirmError = _confirm.text != _next.text
          ? l.securityPasswordMismatch
          : null;
      _banner = null;
    });
    if (_nextError != null || _confirmError != null) return;
    setState(() => _busy = true);
    try {
      await authOf(ref).confirmPasswordReset(widget.token!, _next.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.securityPasswordChangedTitle),
          content: Text(l.resetDoneBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonContinue),
            ),
          ],
        ),
      );
      final session = ref.read(sessionProvider);
      if (session.status == SessionStatus.signedIn) {
        await ref.read(sessionProvider.notifier).signOut();
      } else if (mounted) {
        context.go('/academy/sign-in');
      }
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      if (e.messageKey == 'errors.auth.invalidResetToken') {
        setState(() => _valid = false);
      } else if (e.fields['newPassword'] case final key?) {
        setState(
          () => _nextError = ref
              .read(errorCatalogProvider)
              .message(key, context.languageCode),
        );
      } else {
        setState(() => _banner = errorText(ref, context, e));
      }
    } on Object catch (e) {
      if (mounted) setState(() => _banner = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final academy = ref.watch(sessionProvider).academy;
    return FormScreen(
      title: l.resetTitle,
      children: [
        if (_banner != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _banner!),
          const SizedBox(height: AtlasSpace.s16),
          if (_valid == null)
            AtlasButton(
              label: l.commonRetry,
              style: AtlasButtonStyle.tonal,
              onPressed: _check,
            ),
        ],
        if (_valid == null && _banner == null)
          Text(
            l.resetChecking,
            style: a.type.body.copyWith(color: a.colors.inkSecondary),
          )
        else if (_valid == false) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: l.resetInvalid),
          const SizedBox(height: AtlasSpace.s16),
          AtlasButton(
            label: l.resetRequestNew,
            style: AtlasButtonStyle.tonal,
            onPressed: () => context.pushReplacement('/academy/forgot'),
          ),
        ] else if (_valid == true) ...[
          Text(
            l.resetBody(academy?.name ?? ''),
            style: a.type.body.copyWith(color: a.colors.inkSecondary),
          ),
          const SizedBox(height: AtlasSpace.s20),
          AtlasTextField(
            label: l.securityNewPassword,
            controller: _next,
            password: true,
            helper: l.securityPasswordRule,
            autofillHints: const [AutofillHints.newPassword],
            error: _nextError,
          ),
          const SizedBox(height: AtlasSpace.s12),
          AtlasTextField(
            label: l.securityConfirmPassword,
            controller: _confirm,
            password: true,
            autofillHints: const [AutofillHints.newPassword],
            error: _confirmError,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AtlasSpace.s20),
          AtlasButton(
            label: l.resetSubmit,
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ],
      ],
    );
  }
}
