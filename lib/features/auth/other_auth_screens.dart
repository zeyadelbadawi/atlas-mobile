import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ui_helpers.dart';
import '../../core/auth/auth_repository.dart';
import '../../design/design.dart';
import 'register_screen.dart';
import 'sign_in_flow.dart';

/// Emails a reset link; the link opens the academy's web page (or the app
/// once universal links are set up).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  String? _error, _sentTo, _banner;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _error = validateEmail(context, _email.text);
      _banner = null;
    });
    if (_error != null) return;
    setState(() => _busy = true);
    try {
      await authOf(ref).requestPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sentTo = _email.text.trim());
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
    return FormScreen(
      title: l.forgotTitle,
      children: [
        Text(
          l.forgotBody,
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        const SizedBox(height: AtlasSpace.s20),
        if (_sentTo != null) ...[
          AtlasBanner(
            kind: AtlasBannerKind.success,
            message: l.forgotSent(_sentTo!),
          ),
          const SizedBox(height: AtlasSpace.s16),
        ],
        if (_banner != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _banner!),
          const SizedBox(height: AtlasSpace.s16),
        ],
        AtlasTextField(
          label: l.signInEmail,
          controller: _email,
          hint: 'name@example.com',
          ltrValue: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          error: _error,
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: AtlasSpace.s20),
        AtlasButton(
          label: l.forgotSubmit,
          loading: _busy,
          onPressed: _busy ? null : _send,
        ),
      ],
    );
  }
}

/// Apple returned an email that already has an account: prove it once with
/// the account's password.
class AppleLinkScreen extends ConsumerStatefulWidget {
  const AppleLinkScreen({super.key, required this.step});
  final AppleStepRequired step;

  @override
  ConsumerState<AppleLinkScreen> createState() => _AppleLinkScreenState();
}

class _AppleLinkScreenState extends ConsumerState<AppleLinkScreen> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_password.text.isEmpty) {
      return setState(() => _error = context.l10n.validationPasswordRequired);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await authOf(ref)
          .appleLink(pending: widget.step.pending, password: _password.text);
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
      title: l.appleLinkTitle,
      children: [
        Text(
          l.appleLinkBody(widget.step.email),
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        const SizedBox(height: AtlasSpace.s20),
        AtlasTextField(
          label: l.signInPassword,
          controller: _password,
          password: true,
          ltrValue: true,
          autofillHints: const [AutofillHints.password],
          error: _error,
          onSubmitted: (_) => _link(),
          showPasswordLabel: l.showPassword,
          hidePasswordLabel: l.hidePassword,
        ),
        const SizedBox(height: AtlasSpace.s20),
        AtlasButton(
          label: l.appleLinkSubmit,
          loading: _busy,
          onPressed: _busy ? null : _link,
        ),
      ],
    );
  }
}

/// A new account from Apple: Apple gave name and email; the academy also
/// needs a mobile number, and the learner must confirm age and terms.
class AppleCreateScreen extends ConsumerStatefulWidget {
  const AppleCreateScreen({super.key, required this.step});
  final AppleStepRequired step;

  @override
  ConsumerState<AppleCreateScreen> createState() => _AppleCreateScreenState();
}

class _AppleCreateScreenState extends ConsumerState<AppleCreateScreen> {
  late final _name = TextEditingController(text: widget.step.name);
  final _phone = TextEditingController();
  bool _age = false, _terms = false, _busy = false;
  String? _nameError, _phoneError, _banner;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = context.l10n;
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l.validationNameRequired : null;
      _phoneError = _phone.text.trim().isEmpty
          ? l.validationPhoneRequired
          : null;
      _banner = null;
    });
    if (_nameError != null || _phoneError != null) return;
    setState(() => _busy = true);
    try {
      final outcome = await authOf(ref).appleCreateAccount(
        pending: widget.step.pending,
        name: _name.text.trim(),
        phoneNumber: _phone.text.trim(),
        phoneCountry: 'EG',
        consents: consentRecord(Theme.of(context).platform),
      );
      if (mounted) handleOutcome(context, ref, outcome);
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
    return FormScreen(
      title: l.appleCreateTitle,
      children: [
        Text(
          l.appleCreateBody,
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        const SizedBox(height: AtlasSpace.s20),
        if (_banner != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _banner!),
          const SizedBox(height: AtlasSpace.s16),
        ],
        AtlasTextField(
          label: l.registerName,
          controller: _name,
          error: _nameError,
        ),
        const SizedBox(height: AtlasSpace.s16),
        AtlasTextField(
          label: l.signInEmail,
          controller: TextEditingController(text: widget.step.email),
          ltrValue: true,
          enabled: false,
        ),
        const SizedBox(height: AtlasSpace.s16),
        AtlasTextField(
          label: l.registerPhone,
          controller: _phone,
          hint: '10 0000 0000',
          ltrValue: true,
          prefix: phonePrefix(context),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
          ],
          helper: l.registerPhoneHint,
          error: _phoneError,
        ),
        const SizedBox(height: AtlasSpace.s16),
        ConsentRows(
          onChanged: (age, terms) => setState(() {
            _age = age;
            _terms = terms;
          }),
        ),
        const SizedBox(height: AtlasSpace.s20),
        AtlasButton(
          label: l.registerSubmit,
          loading: _busy,
          onPressed: _age && _terms && !_busy ? _create : null,
        ),
      ],
    );
  }
}
