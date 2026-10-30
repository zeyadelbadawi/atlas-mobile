import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/auth/auth_repository.dart';

/// Moves the app on after any sign-in step answered.
void handleOutcome(BuildContext context, WidgetRef ref, SignInOutcome outcome) {
  switch (outcome) {
    case SignedIn(:final user):
      ref.read(sessionProvider.notifier).signedIn(user);
    case EmailCodeRequired():
      context.push('/academy/code', extra: outcome);
    case AuthenticatorCodeRequired():
      context.push('/academy/totp', extra: outcome);
    case AppleStepRequired():
      context.push(
        outcome.linkRequired ? '/academy/apple-link' : '/academy/apple-create',
        extra: outcome,
      );
  }
}

AuthRepository authOf(WidgetRef ref) =>
    ref.read(sessionProvider.notifier).auth!;

/// The consent record sent with a new account (B4).
Map<String, Object> consentRecord(TargetPlatform platform) => {
  'source': platform == TargetPlatform.iOS ? 'ios' : 'android',
  'termsVersion': _terms,
  'privacyVersion': _privacy,
  'ageConfirmed': true,
};

const _terms = String.fromEnvironment(
  'ATLAS_TERMS_VERSION',
  defaultValue: 'terms-2026-10-09',
);
const _privacy = String.fromEnvironment(
  'ATLAS_PRIVACY_VERSION',
  defaultValue: 'privacy-2026-10-30',
);
