import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_repository.dart';
import '../features/academy_picker/academy_picker_screen.dart';
import '../features/account/account_screen.dart';
import '../features/auth/code_screens.dart';
import '../features/auth/other_auth_screens.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/legal/legal_screens.dart';
import 'providers.dart';

/// Routes open to everyone, whatever the session.
bool _public(String path) => path.startsWith('/legal') || path == '/about';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(sessionProvider).status;
      final path = state.matchedLocation;
      if (_public(path)) return null;
      return switch (s) {
        SessionStatus.noAcademy => path == '/picker' ? null : '/picker',
        SessionStatus.restoring => path == '/loading' ? null : '/loading',
        SessionStatus.signedOut =>
          path.startsWith('/academy/') ? null : '/academy/sign-in',
        SessionStatus.signedIn => path == '/home' ? null : '/home',
      };
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _Loading()),
      GoRoute(path: '/loading', builder: (_, _) => const _Loading()),
      GoRoute(path: '/picker', builder: (_, _) => const AcademyPickerScreen()),
      GoRoute(
        path: '/academy/sign-in',
        builder: (_, s) => SignInScreen(email: s.extra as String?),
      ),
      GoRoute(
        path: '/academy/code',
        builder: (_, s) =>
            EmailCodeScreen(challenge: s.extra! as EmailCodeRequired),
      ),
      GoRoute(
        path: '/academy/totp',
        builder: (_, s) => AuthenticatorCodeScreen(
          challenge: s.extra! as AuthenticatorCodeRequired,
        ),
      ),
      GoRoute(
        path: '/academy/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/academy/forgot',
        builder: (_, s) => ForgotPasswordScreen(email: s.extra as String?),
      ),
      GoRoute(
        path: '/academy/apple-link',
        builder: (_, s) => AppleLinkScreen(step: s.extra! as AppleStepRequired),
      ),
      GoRoute(
        path: '/academy/apple-create',
        builder: (_, s) =>
            AppleCreateScreen(step: s.extra! as AppleStepRequired),
      ),
      GoRoute(path: '/home', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/legal', builder: (_, _) => const LegalListScreen()),
      GoRoute(
        path: '/legal/:doc',
        builder: (_, s) => LegalDocumentScreen(
          doc: LegalDoc.byId(s.pathParameters['doc']!) ?? LegalDoc.terms,
        ),
      ),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
    ],
  );
});

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}
