import 'dart:async';

import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ui_helpers.dart';
import '../../core/auth/auth_repository.dart';
import '../../design/design.dart';
import 'sign_in_flow.dart';

/// The academy emailed a 6-digit code (new device, or `always` mode).
class EmailCodeScreen extends ConsumerStatefulWidget {
  const EmailCodeScreen({super.key, required this.challenge});
  final EmailCodeRequired challenge;

  @override
  ConsumerState<EmailCodeScreen> createState() => _EmailCodeScreenState();
}

class _EmailCodeScreenState extends ConsumerState<EmailCodeScreen> {
  final _code = TextEditingController();
  bool _remember = true, _busy = false;
  String? _error, _info;
  late DateTime _resendAt = widget.challenge.resendAvailableAt;
  late int _resendsLeft = widget.challenge.resendsRemaining;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await authOf(ref).verifyEmailCode(
        challengeId: widget.challenge.challengeId,
        code: _code.text,
        rememberDevice: _remember,
      );
      if (mounted) handleOutcome(context, ref, outcome);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final (at, left) = await authOf(ref)
          .resendEmailCode(widget.challenge.challengeId);
      if (!mounted) return;
      setState(() {
        _resendAt = at;
        _resendsLeft = left;
        _info = context.l10n.codeResent;
        _code.clear();
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final wait = _resendAt.difference(clock.now()).inSeconds;
    return FormScreen(
      title: l.codeTitle,
      children: [
        Text(
          l.codeBody(widget.challenge.maskedEmail),
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        const SizedBox(height: AtlasSpace.s24),
        CodeInput(
          controller: _code,
          hasError: _error != null,
          semanticLabel: l.codeLabel,
          onCompleted: (_) => _verify(),
        ),
        const SizedBox(height: AtlasSpace.s16),
        if (_error != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
          const SizedBox(height: AtlasSpace.s12),
        ],
        if (_info != null) ...[
          AtlasBanner(message: _info!),
          const SizedBox(height: AtlasSpace.s12),
        ],
        CheckboxRow(
          value: _remember,
          onChanged: (v) => setState(() => _remember = v),
          label: TextSpan(
            children: [
              TextSpan(text: l.codeRemember),
              TextSpan(
                text: '\n${l.codeRememberHint}',
                style: a.type.footnote.copyWith(color: a.colors.inkSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AtlasSpace.s20),
        AtlasButton(
          label: l.codeVerify,
          loading: _busy,
          onPressed: _code.text.length == 6 && !_busy ? _verify : null,
        ),
        const SizedBox(height: AtlasSpace.s8),
        if (_resendsLeft > 0)
          AtlasButton(
            label: wait > 0
                ? l.codeResendIn(context.digits('$wait'))
                : l.codeResend,
            style: AtlasButtonStyle.plain,
            onPressed: wait > 0 ? null : _resend,
          ),
      ],
    );
  }
}

/// The account has an authenticator app.
class AuthenticatorCodeScreen extends ConsumerStatefulWidget {
  const AuthenticatorCodeScreen({super.key, required this.challenge});
  final AuthenticatorCodeRequired challenge;

  @override
  ConsumerState<AuthenticatorCodeScreen> createState() =>
      _AuthenticatorCodeScreenState();
}

class _AuthenticatorCodeScreenState
    extends ConsumerState<AuthenticatorCodeScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await authOf(ref).verifyAuthenticatorCode(
        challengeId: widget.challenge.challengeId,
        token: _code.text,
      );
      if (mounted) handleOutcome(context, ref, outcome);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return FormScreen(
      title: l.totpTitle,
      children: [
        Text(
          l.totpBody,
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        const SizedBox(height: AtlasSpace.s24),
        CodeInput(
          controller: _code,
          hasError: _error != null,
          semanticLabel: l.codeLabel,
          onCompleted: (_) => _verify(),
        ),
        const SizedBox(height: AtlasSpace.s16),
        if (_error != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
          const SizedBox(height: AtlasSpace.s12),
        ],
        AtlasButton(
          label: l.codeVerify,
          loading: _busy,
          onPressed: _code.text.length == 6 && !_busy ? _verify : null,
        ),
      ],
    );
  }
}
