import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/academy/academy.dart';
import '../core/api/api_error.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'push.dart';
import 'router.dart';
import 'web_paths.dart';

/// What an academy link asks the app to do.
sealed class LinkAction {
  const LinkAction();
}

/// Just open the academy (its home page, sign-in, a page the app lacks).
class OpenAcademy extends LinkAction {
  const OpenAcademy();
}

/// A signed-in screen, e.g. `/catalog/:id` or `/course/:id/lesson/:id`.
class OpenScreen extends LinkAction {
  const OpenScreen(this.path);
  final String path;
}

/// `/verify-email?token=…`: completes for the account's own session only.
class VerifyEmailLink extends LinkAction {
  const VerifyEmailLink(this.token);
  final String token;
}

/// `/reset-password?token=…`: works signed in or out.
class ResetPasswordLink extends LinkAction {
  const ResetPasswordLink(this.token);
  final String token;
}

/// A page the app does not show (buying, payments, certificate check):
/// opened in a browser tab, so it never loops back into the app.
class OpenInBrowser extends LinkAction {
  const OpenInBrowser(this.uri);
  final Uri uri;
}

class AcademyLink {
  const AcademyLink(this.host, this.action);
  final String host;
  final LinkAction action;
}

/// Reads an academy website address (from an App Link, a QR code or a
/// pasted link) the way the website's own router does: an optional
/// language prefix, then the page. Returns null for anything that is not
/// an http(s) address.
AcademyLink? parseAcademyLink(Uri uri) {
  if (!uri.hasScheme && uri.path.contains('.')) {
    // `ziadd.atlass.dpdns.org/courses/x`, typed without https://.
    return parseAcademyLink(Uri.parse('https://${uri.toString()}'));
  }
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  final host = uri.host.toLowerCase();
  if (host.isEmpty || !host.contains('.') && host != 'localhost') return null;
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if (parts.isNotEmpty && (parts.first == 'ar' || parts.first == 'en')) {
    parts.removeAt(0);
  }
  final token = uri.queryParameters['token']?.trim();
  final LinkAction action = switch (parts) {
    ['courses'] => const OpenScreen('/catalog'),
    ['courses', final id] => OpenScreen('/catalog/$id'),
    ['verify-email'] when token != null && token.isNotEmpty => VerifyEmailLink(
      token,
    ),
    ['verify-email'] => const OpenScreen('/account/profile'),
    ['reset-password'] when token != null && token.isNotEmpty =>
      ResetPasswordLink(token),
    ['reset-password'] ||
    ['forgot-password'] => const OpenScreen('/academy/forgot'),
    ['my', 'purchases' || 'payments', ...] ||
    ['my', 'courses', _, 'checkout', ...] ||
    ['verify', _] => OpenInBrowser(uri),
    ['my', ...] => OpenScreen(appPathForWebLink('/${parts.join('/')}')),
    _ => const OpenAcademy(),
  };
  return AcademyLink(host, action);
}

/// Takes academy links from the system (App Links / Universal Links) and
/// the QR scanner, switches academy when the link belongs to another one,
/// and opens the screen once the session allows it (a link that needs
/// sign-in waits on the sign-in screen and opens right after).
class DeepLinkController extends Notifier<AcademyLink?> {
  StreamSubscription<Uri>? _sub;

  @override
  AcademyLink? build() {
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  /// Listens for links while the app runs; the link that launched the app
  /// arrives on the same stream.
  void start() {
    if (_sub != null) return;
    try {
      _sub = AppLinks().uriLinkStream.listen(
        (uri) => open(uri),
        onError: (_) {},
      );
    } on Object {
      // No platform channel (tests): links simply never arrive.
    }
  }

  /// Returns false when the link is not an academy address at all.
  Future<bool> open(Uri uri) async {
    final link = parseAcademyLink(uri);
    if (link == null) return false;
    if (link.action case OpenInBrowser(:final uri)) {
      await _browser(uri);
      return true;
    }
    final session = ref.read(sessionProvider);
    final current = session.academy;
    if (current == null || current.host.toLowerCase() != link.host) {
      final Academy academy;
      try {
        academy = await ref.read(academyDirectoryProvider).resolve(link.host);
      } on AtlasApiException catch (e) {
        // Not an academy (the dashboard, the help site): its own page.
        if (e.status == 404) {
          await _browser(uri);
        } else {
          _toast((l) => l.linkOpenFailed);
        }
        return true;
      } on Object {
        _toast((l) => l.linkOpenFailed);
        return true;
      }
      if (current == null || academy.id != current.id) {
        if (current != null &&
            session.status == SessionStatus.signedIn &&
            !await _confirmSwitch(academy, current)) {
          return true;
        }
        state = link;
        await ref.read(sessionProvider.notifier).chooseAcademy(academy);
        consume();
        return true;
      }
    }
    state = link;
    consume();
    return true;
  }

  /// Waits to open [link] in the academy the learner just chose (a full
  /// link typed or scanned in the academy picker).
  void queue(AcademyLink link) {
    if (link.action is OpenAcademy) return;
    state = link;
    consume();
  }

  /// Opens the waiting link if the session now allows it. Called after
  /// every session change, a frame later so the router has applied its own
  /// redirect (sign-in → home) first.
  void consume() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _consumeNow());

  void _consumeNow() {
    final link = state;
    if (link == null) return;
    final status = ref.read(sessionProvider).status;
    if (status == SessionStatus.restoring ||
        status == SessionStatus.noAcademy) {
      return;
    }
    final router = ref.read(routerProvider);
    switch (link.action) {
      case OpenAcademy():
        state = null;
      case OpenInBrowser(:final uri):
        state = null;
        unawaited(_browser(uri));
      case ResetPasswordLink(:final token):
        state = null;
        _pushOver(router, status, '/academy/reset-password', token);
      case OpenScreen(:final path) when path.startsWith('/academy/'):
        state = null;
        if (status == SessionStatus.signedOut) {
          _pushOver(router, status, path, null);
        }
      case OpenScreen(:final path):
        if (status != SessionStatus.signedIn) return;
        state = null;
        _pushOver(router, status, path, null);
      case VerifyEmailLink(:final token):
        if (status != SessionStatus.signedIn) return;
        state = null;
        _pushOver(router, status, '/account/verify-email', token);
    }
  }

  /// Pushes over the session's base screen, so Back from a link lands on
  /// Home (or sign-in), never on a loading or picker screen.
  void _pushOver(
    GoRouter router,
    SessionStatus status,
    String path,
    Object? extra,
  ) {
    final here = router.routerDelegate.currentConfiguration.uri.path;
    if (here == '/' ||
        here == '/loading' ||
        here == '/picker' ||
        (status == SessionStatus.signedIn && here.startsWith('/academy/'))) {
      router.go(
        status == SessionStatus.signedIn ? '/home' : '/academy/sign-in',
      );
    }
    router.push(path, extra: extra);
  }

  Future<bool> _confirmSwitch(Academy next, Academy current) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return false;
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.linkSwitchTitle(next.name)),
        content: Text(l.linkSwitchBody(next.name, current.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.linkSwitchOpen),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _browser(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } on Object {
      _toast((l) => l.linkOpenFailed);
    }
  }

  void _toast(String Function(AppLocalizations) text) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(text(AppLocalizations.of(context)))),
    );
  }
}

final deepLinkProvider = NotifierProvider<DeepLinkController, AcademyLink?>(
  DeepLinkController.new,
);

/// Shared with the router so link prompts have a context.
final rootNavigatorKey = GlobalKey<NavigatorState>();
