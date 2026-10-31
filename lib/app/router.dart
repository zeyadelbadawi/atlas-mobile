import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_repository.dart';
import '../features/academy_picker/academy_picker_screen.dart';
import '../features/academy_picker/qr_scan_screen.dart';
import '../features/account/account_screen.dart';
import '../features/account/account_settings_screens.dart';
import '../features/account/devices_screen.dart';
import '../features/courses/course_screen.dart';
import '../features/courses/my_courses_screen.dart';
import '../features/home/home_screen.dart';
import '../features/assignment/assignment_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/course_preview_screen.dart';
import '../features/catalog/reviews.dart';
import '../features/certificates/certificates_screen.dart';
import '../features/learning/item_redirect_screen.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/notifications/announcements_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/results/results_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/auth/code_screens.dart';
import '../features/auth/other_auth_screens.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/legal/legal_screens.dart';
import '../features/links/link_screens.dart';
import 'deep_links.dart';
import 'providers.dart';
import 'push.dart';

/// Routes open to everyone, whatever the session.
bool _public(String path) => path.startsWith('/legal') || path == '/about';

bool _signedInPath(String path) =>
    path == '/home' ||
    path.startsWith('/courses') ||
    path == '/tasks' ||
    path.startsWith('/course/') ||
    path.startsWith('/catalog') ||
    path.startsWith('/account') ||
    path.startsWith('/notifications') ||
    path.startsWith('/announcements');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(sessionProvider).status;
      final path = state.matchedLocation;
      final target = _public(path)
          ? null
          : switch (s) {
              SessionStatus.noAcademy =>
                path.startsWith('/picker') ? null : '/picker',
              SessionStatus.restoring => path == '/loading' ? null : '/loading',
              SessionStatus.signedOut =>
                path.startsWith('/academy/') ? null : '/academy/sign-in',
              SessionStatus.signedIn =>
                _signedInPath(path) || path == '/academy/reset-password'
                    ? null
                    : '/home',
            };
      // Route templates only (`/course/:id`), never ids or names.
      if (target == null) {
        ref.read(analyticsProvider).screen(state.fullPath ?? path);
      }
      return target;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _Loading()),
      GoRoute(path: '/loading', builder: (_, _) => const _Loading()),
      GoRoute(path: '/picker', builder: (_, _) => const AcademyPickerScreen()),
      GoRoute(path: '/picker/scan', builder: (_, _) => const QrScanScreen()),
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
        builder: (_, s) => RegisterScreen(email: s.extra as String?),
      ),
      GoRoute(
        path: '/academy/forgot',
        builder: (_, s) => ForgotPasswordScreen(email: s.extra as String?),
      ),
      GoRoute(
        path: '/academy/reset-password',
        builder: (_, s) => ResetPasswordScreen(token: s.extra as String?),
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
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses',
                builder: (_, _) => const MyCoursesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (_, _) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/catalog', builder: (_, _) => const CatalogScreen()),
      GoRoute(
        path: '/catalog/:id',
        builder: (_, s) =>
            CoursePreviewScreen(idOrSlug: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/catalog/:id/reviews',
        builder: (_, s) =>
            CourseReviewsScreen(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (_, s) => CourseScreen(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/lesson/:lessonId',
        builder: (_, s) => LessonScreen(
          courseId: s.pathParameters['id']!,
          lessonId: s.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/item/:itemId',
        builder: (_, s) => ItemRedirectScreen(
          courseId: s.pathParameters['id']!,
          itemId: s.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: '/announcements',
        builder: (_, _) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (_, s) =>
            AnnouncementDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/quiz/:quizId',
        builder: (_, s) => QuizScreen(
          courseId: s.pathParameters['id']!,
          quizId: s.pathParameters['quizId']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/assignment/:assignmentId',
        builder: (_, s) => AssignmentScreen(
          courseId: s.pathParameters['id']!,
          assignmentId: s.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/account/results',
        builder: (_, _) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/account/certificates',
        builder: (_, _) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/account/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/security',
        builder: (_, _) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/account/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/account/verify-email',
        builder: (_, s) => VerifyEmailScreen(token: s.extra as String?),
      ),
      GoRoute(
        path: '/account/privacy',
        builder: (_, _) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/account/devices',
        builder: (_, _) => const DevicesScreen(),
      ),
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
