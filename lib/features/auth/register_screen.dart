import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../app/providers.dart';
import '../../design/design.dart';
import 'sign_in_flow.dart';

/// Egypt only for now; the backend validates the number for the country.
const _phoneCountry = 'EG';

/// The age and terms rows, unchecked until the learner checks them. Links
/// open the documents without toggling.
class ConsentRows extends StatefulWidget {
  const ConsentRows({super.key, required this.onChanged});
  final void Function(bool age, bool terms) onChanged;

  @override
  State<ConsentRows> createState() => _ConsentRowsState();
}

class _ConsentRowsState extends State<ConsentRows> {
  bool _age = false, _terms = false;
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => context.push('/legal/terms');
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => context.push('/legal/privacy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final link = TextStyle(
      color: context.atlas.colors.accent,
      decoration: TextDecoration.underline,
      decorationColor: context.atlas.colors.accent,
    );
    return Column(
      children: [
        CheckboxRow(
          value: _age,
          onChanged: (v) {
            setState(() => _age = v);
            widget.onChanged(_age, _terms);
          },
          label: TextSpan(text: l.registerAge),
        ),
        CheckboxRow(
          value: _terms,
          onChanged: (v) {
            setState(() => _terms = v);
            widget.onChanged(_age, _terms);
          },
          semanticLabel:
              '${l.registerAgreePrefix}${l.registerTerms}${l.registerAgreeAnd}${l.registerPrivacy}',
          label: TextSpan(
            children: [
              TextSpan(text: l.registerAgreePrefix),
              TextSpan(
                text: l.registerTerms,
                style: link,
                recognizer: _termsTap,
              ),
              TextSpan(text: l.registerAgreeAnd),
              TextSpan(
                text: l.registerPrivacy,
                style: link,
                recognizer: _privacyTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The +20 prefix shown inside the phone field.
Widget phonePrefix(BuildContext context) => Text(
  '+20',
  textDirection: TextDirection.ltr,
  style: context.atlas.type.body.copyWith(
    color: context.atlas.colors.inkSecondary,
  ),
);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _age = false, _terms = false, _busy = false, _existing = false;
  String? _nameError, _emailError, _phoneError, _passwordError, _banner;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() {
      _nameError = _name.text.trim().length < 2
          ? l.validationNameRequired
          : null;
      _emailError = validateEmail(context, _email.text);
      _phoneError = _phone.text.trim().isEmpty
          ? l.validationPhoneRequired
          : null;
      _passwordError = _password.text.length < 8
          ? l.validationPasswordShort
          : null;
      _banner = null;
      _existing = false;
    });
    if ([
      _nameError,
      _emailError,
      _phoneError,
      _passwordError,
    ].any((e) => e != null)) {
      return;
    }
    setState(() => _busy = true);
    final auth = authOf(ref);
    try {
      final account = await auth.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phoneNumber: _phone.text.trim(),
        phoneCountry: _phoneCountry,
        consents: consentRecord(Theme.of(context).platform),
      );
      if (account == 'existing') {
        if (mounted) setState(() => _existing = true);
        return;
      }
      final outcome = await auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) handleOutcome(context, ref, outcome);
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _existing =
            e.messageKey == 'errors.auth.emailAlreadyRegistered' ||
            e.messageKey == 'errors.auth.alreadyLearnerHere';
        _banner = _existing ? null : errorText(ref, context, e);
        _phoneError = e.fields['phoneNumber'] != null
            ? ref
                  .read(errorCatalogProvider)
                  .message(e.fields['phoneNumber']!, context.languageCode)
            : _phoneError;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _banner = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormScreen(
      title: l.registerTitle,
      children: [
        if (_existing) ...[
          AtlasBanner(message: l.registerExisting),
          const SizedBox(height: AtlasSpace.s12),
          AtlasButton(
            label: l.signInSubmit,
            style: AtlasButtonStyle.tonal,
            onPressed: () =>
                context.go('/academy/sign-in', extra: _email.text.trim()),
          ),
          const SizedBox(height: AtlasSpace.s20),
        ],
        if (_banner != null) ...[
          AtlasBanner(kind: AtlasBannerKind.error, message: _banner!),
          const SizedBox(height: AtlasSpace.s16),
        ],
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasTextField(
                label: l.registerName,
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                error: _nameError,
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasTextField(
                label: l.signInEmail,
                controller: _email,
                hint: 'name@example.com',
                ltrValue: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                error: _emailError,
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasTextField(
                label: l.registerPhone,
                controller: _phone,
                hint: '10 0000 0000',
                ltrValue: true,
                prefix: phonePrefix(context),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
                helper: l.registerPhoneHint,
                error: _phoneError,
              ),
              const SizedBox(height: AtlasSpace.s16),
              AtlasTextField(
                label: l.registerPassword,
                controller: _password,
                password: true,
                ltrValue: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                helper: l.registerPasswordHint,
                error: _passwordError,
                showPasswordLabel: l.showPassword,
                hidePasswordLabel: l.hidePassword,
              ),
            ],
          ),
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
          onPressed: _age && _terms && !_busy ? _submit : null,
        ),
        if (!(_age && _terms)) ...[
          const SizedBox(height: AtlasSpace.s8),
          Text(
            l.registerNeedsConsent,
            textAlign: TextAlign.center,
            style: context.atlas.type.footnote.copyWith(
              color: context.atlas.colors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
