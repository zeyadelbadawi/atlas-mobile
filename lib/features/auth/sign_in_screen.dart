import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../design/design.dart';
import 'sign_in_flow.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  String? _emailError, _passwordError, _banner;
  bool _busy = false, _notMember = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final l = context.l10n;
    setState(() {
      _emailError = validateEmail(context, _email.text);
      _passwordError = _password.text.isEmpty
          ? l.validationPasswordRequired
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _banner = null;
    });
    try {
      await action();
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notMember = e.messageKey == 'errors.auth.notAMemberOfAcademy';
        _banner = _notMember
            ? context.l10n.signInNotMember
            : errorText(ref, context, e);
      });
    } on Object catch (e) {
      if (mounted) setState(() => _banner = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    if (!_validate()) return;
    await _run(() async {
      final outcome = await authOf(ref)
          .signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) handleOutcome(context, ref, outcome);
    });
  }

  Future<void> _join() async {
    if (!_validate()) return;
    await _run(() async {
      await authOf(ref)
          .joinAcademy(email: _email.text.trim(), password: _password.text);
      final outcome = await authOf(ref)
          .signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) handleOutcome(context, ref, outcome);
    });
  }

  Future<void> _apple() async {
    await _run(() async {
      final raw = _nonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      final outcome = await authOf(ref).appleNative(
        identityToken: credential.identityToken!,
        rawNonce: raw,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      if (mounted) handleOutcome(context, ref, outcome);
    }).catchError((Object e) {
      // The learner closed Apple's sheet: nothing to report.
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return;
      }
    });
  }

  static String _nonce() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._';
    final r = Random.secure();
    return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final session = ref.watch(sessionProvider);
    final academy = session.academy!;
    final config = ref.watch(mobileConfigProvider).value;
    final showApple =
        Theme.of(context).platform == TargetPlatform.iOS &&
        (config?.signInWithApple ?? false);
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoverBand.compact(
              academyName: academy.name,
              host: academy.host,
              logo: NetworkImage(academy.logoUrl.toString()),
            ),
            Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: ReadableWidth(
                form: true,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l.signInTitle,
                          style: a.type.title1.copyWith(color: a.colors.ink),
                        ),
                      ),
                      const SizedBox(height: AtlasSpace.s20),
                      if (_banner != null) ...[
                        AtlasBanner(
                          kind: AtlasBannerKind.error,
                          message: _banner!,
                        ),
                        const SizedBox(height: AtlasSpace.s16),
                      ],
                      AtlasTextField(
                        label: l.signInEmail,
                        controller: _email,
                        hint: 'name@example.com',
                        ltrValue: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.username,
                        ],
                        error: _emailError,
                      ),
                      const SizedBox(height: AtlasSpace.s16),
                      AtlasTextField(
                        label: l.signInPassword,
                        controller: _password,
                        password: true,
                        ltrValue: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        error: _passwordError,
                        onSubmitted: (_) => _signIn(),
                        showPasswordLabel: l.showPassword,
                        hidePasswordLabel: l.hidePassword,
                      ),
                      const SizedBox(height: AtlasSpace.s24),
                      if (_notMember)
                        AtlasButton(
                          label: l.signInJoinAcademy,
                          loading: _busy,
                          onPressed: _busy ? null : _join,
                        )
                      else
                        AtlasButton(
                          label: l.signInSubmit,
                          loading: _busy,
                          onPressed: _busy ? null : _signIn,
                        ),
                      const SizedBox(height: AtlasSpace.s8),
                      AtlasButton(
                        label: l.signInForgot,
                        style: AtlasButtonStyle.plain,
                        onPressed: () => context.push(
                          '/academy/forgot',
                          extra: _email.text.trim(),
                        ),
                      ),
                      if (showApple) ...[
                        const SizedBox(height: AtlasSpace.s8),
                        SizedBox(
                          height: AtlasSize.button,
                          child: SignInWithAppleButton(
                            onPressed: _busy ? () {} : _apple,
                            style: a.colors.brightness == Brightness.dark
                                ? SignInWithAppleButtonStyle.white
                                : SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AtlasRadius.lg),
                            ),
                            height: AtlasSize.button,
                          ),
                        ),
                      ],
                      const SizedBox(height: AtlasSpace.s32),
                      Text(
                        l.signInNoAccount,
                        textAlign: TextAlign.center,
                        style: a.type.subhead.copyWith(
                          color: a.colors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: AtlasSpace.s8),
                      AtlasButton(
                        label: l.signInCreateAccount,
                        style: AtlasButtonStyle.tonal,
                        onPressed: () => context.push('/academy/register'),
                      ),
                      const SizedBox(height: AtlasSpace.s24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AtlasSpace.s8,
                        children: [
                          TextButton(
                            onPressed: () => ref
                                .read(sessionProvider.notifier)
                                .leaveAcademy(),
                            child: Text(l.signInChangeAcademy),
                          ),
                          TextButton(
                            onPressed: () => context.push('/legal'),
                            child: Text(l.legalTitle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
