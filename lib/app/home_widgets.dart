import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../core/clock.dart';
import '../core/learning/assessment_models.dart';
import '../l10n/app_localizations.dart';
import 'learning_providers.dart';
import 'providers.dart';
import 'push.dart';
import 'router.dart';

/// What the home-screen widget shows, already in the app's language: the
/// widget only lays it out.
typedef WidgetData = Map<String, Object?>;

/// The home-screen widgets (Android AppWidget, iOS WidgetKit), behind an
/// interface for tests.
abstract class HomeWidgets {
  Future<void> save(WidgetData data);

  /// Taps on a widget, as the app path they carry.
  Stream<String> get taps;
  Future<String?> launchPath();
}

class PlatformHomeWidgets implements HomeWidgets {
  /// The iOS App Group the app and its widget extension share.
  static const appGroup = 'group.com.atlas.atlasMobile';
  static const _android = 'com.atlas.atlas_mobile.ContinueWidget';
  static const _ios = 'AtlasContinueWidget';

  bool _grouped = false;

  @override
  Future<void> save(WidgetData data) async {
    if (!_grouped) {
      _grouped = true;
      await HomeWidget.setAppGroupId(appGroup);
    }
    for (final MapEntry(:key, :value) in data.entries) {
      await HomeWidget.saveWidgetData<Object>(key, value);
    }
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _android,
      iOSName: _ios,
    );
  }

  static String? _path(Uri? uri) => uri?.queryParameters['path'];

  @override
  Stream<String> get taps =>
      HomeWidget.widgetClicked.map(_path).where((p) => p != null).cast();

  @override
  Future<String?> launchPath() async =>
      _path(await HomeWidget.initiallyLaunchedFromHomeWidget());
}

final homeWidgetsProvider = Provider<HomeWidgets>((_) => PlatformHomeWidgets());

/// Keeps the "continue learning" widget current: the course in progress,
/// its next lesson and progress, and the nearest due date. Written on
/// sign-in, on return to the app, after a lesson or a submission; cleared to
/// "sign in" on sign-out. A tap opens the course (or the task).
class HomeWidgetSync extends Notifier<void> {
  bool _attached = false;
  DateTime? _last;
  StreamSubscription<String>? _taps;

  @override
  void build() {
    ref.listen(
      sessionProvider.select((s) => s.status),
      (_, _) => unawaited(refresh(force: true)),
    );
    ref.listen(
      appSettingsProvider.select((s) => s.languageCode),
      (_, _) => unawaited(refresh(force: true)),
    );
    final life = AppLifecycleListener(onResume: () => unawaited(refresh()));
    ref.onDispose(() {
      life.dispose();
      unawaited(_taps?.cancel());
    });
  }

  HomeWidgets get _widgets => ref.read(homeWidgetsProvider);

  /// Once, after the router exists.
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    try {
      _taps = _widgets.taps.listen(_open);
      final first = await _widgets.launchPath();
      if (first != null) _open(first);
    } on Object catch (e) {
      debugPrint('home widget: $e');
    }
    await refresh(force: true);
  }

  void _open(String path) => unawaited(_goWhenSignedIn(path));

  Future<void> _goWhenSignedIn(String path) async {
    for (var i = 0; i < 20; i++) {
      if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
        ref.read(analyticsProvider).event('home_widget_open');
        final router = ref.read(routerProvider);
        path.startsWith('/course/') ? router.push(path) : router.go(path);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  AppLocalizations _strings() {
    final code =
        ref.read(appSettingsProvider).languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return lookupAppLocalizations(Locale(code == 'ar' ? 'ar' : 'en'));
  }

  /// Rewrites the widget from fresh data; back in front, at most every
  /// five minutes.
  Future<void> refresh({bool force = false}) async {
    if (!_attached) return;
    final now = clockNow();
    if (!force &&
        _last != null &&
        now.difference(_last!) < const Duration(minutes: 5)) {
      return;
    }
    _last = now;
    try {
      await _widgets.save(await _data());
    } on Object catch (e) {
      debugPrint('home widget: $e');
    }
  }

  Future<WidgetData> _data() async {
    final l = _strings();
    final session = ref.read(sessionProvider);
    final base = <String, Object?>{
      'rtl': l.localeName == 'ar',
      'label': l.widgetContinue,
      'empty': l.widgetSignIn,
      'signedIn': false,
      'academy': session.academy?.name ?? 'Atlas',
      'course': '',
      'lesson': '',
      'percent': 0,
      'percentText': '',
      'due': '',
      'path': '/home',
    };
    if (session.status != SessionStatus.signedIn) return base;
    final overview = await ref.read(learningRepositoryProvider).overview();
    final c = overview.continueLearning.firstOrNull;
    final pct = c == null ? 0 : c.percentage.round().clamp(0, 100);
    String due = '';
    try {
      final tasks = await ref.read(assessmentRepositoryProvider).tasks();
      final next =
          (tasks
                  .where(
                    (t) =>
                        t.group == TaskGroup.todo &&
                        t.dueAt != null &&
                        t.dueAt!.isAfter(clockNow()),
                  )
                  .toList()
                ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!)))
              .firstOrNull;
      if (next != null) {
        // "Tue 8:00 PM": the day and time, in the app's language.
        final when = DateFormat.E(l.localeName)
            .add_jm()
            .format(next.dueAt!.toLocal());
        due = l.widgetDue(next.title, _digits(l, when));
      }
    } on Object {
      // The due line is a bonus; the widget still shows the course.
    }
    return {
      ...base,
      'signedIn': true,
      'empty': l.widgetNothing,
      'course': c?.courseTitle ?? '',
      'lesson': c?.nextItemTitle == null ? '' : l.widgetNext(c!.nextItemTitle!),
      'percent': pct,
      'percentText': c == null ? '' : l.widgetPercent(_digits(l, '$pct')),
      'due': due,
      'path': c == null ? '/courses' : '/course/${c.courseId}',
    };
  }

  static String _digits(AppLocalizations l, String s) {
    if (l.localeName != 'ar') return s;
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return s.replaceAllMapped(RegExp('[0-9]'), (m) => d[int.parse(m[0]!)]);
  }
}

final homeWidgetSyncProvider = NotifierProvider<HomeWidgetSync, void>(
  HomeWidgetSync.new,
);
