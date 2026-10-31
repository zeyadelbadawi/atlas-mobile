import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../l10n/app_localizations.dart';
import 'learning_providers.dart';
import 'providers.dart';
import 'router.dart';

/// A long press on the app icon: an app path, a title, an icon name
/// (an Android drawable; iOS shows the title alone).
typedef AppShortcut = ({String path, String title, String icon});

/// The system's app-icon shortcuts, behind an interface for tests.
abstract class AppShortcuts {
  void listen(void Function(String path) onOpen);
  Future<void> set(List<AppShortcut> items);
}

class PlatformShortcuts implements AppShortcuts {
  final _actions = const QuickActions();

  // The path rides in the type, which must be unique: one per path.
  @override
  void listen(void Function(String path) onOpen) =>
      unawaited(_actions.initialize(onOpen));

  @override
  Future<void> set(List<AppShortcut> items) => _actions.setShortcutItems([
    for (final s in items)
      ShortcutItem(type: s.path, localizedTitle: s.title, icon: s.icon),
  ]);
}

final appShortcutsProvider = Provider<AppShortcuts>((_) => PlatformShortcuts());

/// Keeps the app icon's shortcuts in step: shown only while signed in, in
/// the app's language, "Continue" pointing at the course in progress.
class ShortcutsController extends Notifier<void> {
  bool _listening = false;

  @override
  void build() {
    ref.listen(
      sessionProvider.select((s) => s.status),
      (_, _) => unawaited(refresh()),
    );
    ref.listen(
      appSettingsProvider.select((s) => s.languageCode),
      (_, _) => unawaited(refresh()),
    );
  }

  /// Once, after the router exists.
  Future<void> attach() async {
    if (_listening) return;
    _listening = true;
    try {
      ref.read(appShortcutsProvider).listen(_open);
    } on Object catch (e) {
      debugPrint('shortcuts: $e');
    }
    await refresh();
  }

  void _open(String path) => unawaited(_goWhenSignedIn(path));

  Future<void> _goWhenSignedIn(String path) async {
    for (var i = 0; i < 20; i++) {
      if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
        final router = ref.read(routerProvider);
        // A tab is gone to; a course opens on top of where the app is, so
        // Back has somewhere to go.
        path.startsWith('/course/') ? router.push(path) : router.go(path);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> refresh() async {
    if (!_listening) return;
    final shortcuts = ref.read(appShortcutsProvider);
    try {
      if (ref.read(sessionProvider).status != SessionStatus.signedIn) {
        await shortcuts.set(const []);
        return;
      }
      final code =
          ref.read(appSettingsProvider).languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final l = lookupAppLocalizations(Locale(code == 'ar' ? 'ar' : 'en'));
      String? course;
      try {
        final o = await ref.read(learningRepositoryProvider).overview();
        course = o.continueLearning.firstOrNull?.courseId;
      } on Object {
        // Offline: "Continue" opens My courses instead.
      }
      await shortcuts.set([
        (
          path: course == null ? '/courses' : '/course/$course',
          title: l.shortcutContinue,
          icon: 'ic_shortcut_continue',
        ),
        (path: '/tasks', title: l.tabTasks, icon: 'ic_shortcut_tasks'),
        (
          path: '/account/notes',
          title: l.notesTitle,
          icon: 'ic_shortcut_notes',
        ),
        (
          path: '/notifications',
          title: l.notificationsTitle,
          icon: 'ic_shortcut_notifications',
        ),
      ]);
    } on Object catch (e) {
      debugPrint('shortcuts: $e');
    }
  }
}

final shortcutsProvider = NotifierProvider<ShortcutsController, void>(
  ShortcutsController.new,
);
