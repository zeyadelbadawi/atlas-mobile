import 'dart:async';

import '../core/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/assessment_models.dart';
import '../core/reminders/local_reminders.dart';
import '../l10n/app_localizations.dart';
import 'learning_providers.dart';
import 'providers.dart';
import 'push.dart';
import 'router.dart';

final localRemindersProvider = Provider<LocalReminders>(
  (_) => PluginReminders(),
);

/// What the learner turned on, kept on this phone.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.daily = false,
    this.time = const TimeOfDay(hour: 20, minute: 0),
    this.deadlines = false,
  });

  final bool daily;
  final TimeOfDay time;
  final bool deadlines;

  bool get any => daily || deadlines;

  ReminderSettings copyWith({bool? daily, TimeOfDay? time, bool? deadlines}) =>
      ReminderSettings(
        daily: daily ?? this.daily,
        time: time ?? this.time,
        deadlines: deadlines ?? this.deadlines,
      );
}

/// The daily study reminder and the due-date reminders. All on the phone:
/// the backend sends no "due soon" message for quizzes and assignments
/// (it does for live sessions, so those are left to it).
///
/// Rescheduled from fresh data whenever it may have changed: on sign-in,
/// when the app comes back to the front, after a submission, and when a
/// setting changes. Cleared on sign-out (they name this account's work).
class RemindersController extends Notifier<ReminderSettings> {
  static const _dailyKey = 'reminders.daily';
  static const _timeKey = 'reminders.time';
  static const _deadlinesKey = 'reminders.deadlines';

  /// The daily reminder's id; due-date reminders count up from 100.
  static const dailyId = 1;
  static const _firstDeadlineId = 100;

  /// Nearest items reminded (two reminders each); iOS keeps 64 pending.
  static const maxItems = 20;

  bool _initialised = false;
  DateTime? _lastSync;

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final time = prefs.getString(_timeKey)?.split(':');
    ref.listen(sessionProvider.select((s) => s.status), (before, status) {
      if (status == SessionStatus.signedIn) {
        unawaited(sync());
      } else if (before == SessionStatus.signedIn) {
        unawaited(_cancel());
      }
    });
    final life = AppLifecycleListener(onResume: () => unawaited(sync()));
    ref.onDispose(life.dispose);
    return ReminderSettings(
      daily: prefs.getBool(_dailyKey) ?? false,
      deadlines: prefs.getBool(_deadlinesKey) ?? false,
      time: time != null && time.length == 2
          ? TimeOfDay(
              hour: int.tryParse(time[0]) ?? 20,
              minute: int.tryParse(time[1]) ?? 0,
            )
          : const TimeOfDay(hour: 20, minute: 0),
    );
  }

  LocalReminders get _local => ref.read(localRemindersProvider);

  /// Once, after the router exists: a tapped reminder opens its screen.
  Future<void> attach() async {
    if (_initialised) return;
    _initialised = true;
    try {
      await _local.init(_open);
    } on Object catch (e) {
      debugPrint('reminders init: $e');
    }
    if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
      await sync(force: true);
    }
  }

  void _open(String path) {
    ref.read(analyticsProvider).event('reminder_open');
    unawaited(_goWhenSignedIn(path));
  }

  Future<void> _goWhenSignedIn(String path) async {
    for (var i = 0; i < 20; i++) {
      if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
        ref.read(routerProvider).push(path);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Turning a reminder on asks the system first. False when refused (the
  /// setting stays off).
  Future<bool> setDaily(bool on) => _set(state.copyWith(daily: on), on);

  Future<bool> setDeadlines(bool on) => _set(state.copyWith(deadlines: on), on);

  Future<void> setTime(TimeOfDay time) async {
    await _set(state.copyWith(time: time), false);
  }

  Future<bool> _set(ReminderSettings next, bool turningOn) async {
    if (turningOn) {
      var granted = false;
      try {
        await _local.init(_open);
        granted = await _local.requestPermission();
      } on Object catch (e) {
        debugPrint('reminders permission: $e');
      }
      if (!granted) return false;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_dailyKey, next.daily);
    await prefs.setBool(_deadlinesKey, next.deadlines);
    await prefs.setString(
      _timeKey,
      '${next.time.hour}:${next.time.minute.toString().padLeft(2, '0')}',
    );
    state = next;
    ref.read(analyticsProvider).event('reminders_set', {
      'daily': next.daily ? 1 : 0,
      'deadlines': next.deadlines ? 1 : 0,
    });
    await sync(force: true);
    return true;
  }

  Future<void> _cancel() async {
    try {
      await _local.cancelAll();
    } on Object catch (e) {
      debugPrint('reminders cancel: $e');
    }
  }

  /// Reschedules everything from fresh data. Back in front, at most every
  /// ten minutes; [force] for a change the learner just made.
  Future<void> sync({bool force = false}) async {
    if (!_initialised) return;
    final now = clockNow();
    if (!force &&
        _lastSync != null &&
        now.difference(_lastSync!) < const Duration(minutes: 10)) {
      return;
    }
    _lastSync = now;
    final s = state;
    if (ref.read(sessionProvider).status != SessionStatus.signedIn) return;
    await _cancel();
    if (!s.any) return;
    final l = _strings();
    try {
      if (s.daily) await _scheduleDaily(l, s.time);
      if (s.deadlines) await _scheduleDeadlines(l, now);
    } on Object catch (e) {
      debugPrint('reminders sync: $e');
    }
  }

  AppLocalizations _strings() {
    final code =
        ref.read(appSettingsProvider).languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return lookupAppLocalizations(Locale(code == 'ar' ? 'ar' : 'en'));
  }

  Future<void> _scheduleDaily(AppLocalizations l, TimeOfDay time) async {
    String? course, path;
    try {
      final overview = await ref.read(learningRepositoryProvider).overview();
      final first = overview.continueLearning.firstOrNull;
      course = first?.courseTitle;
      if (first != null) path = '/course/${first.courseId}';
    } on Object {
      // No network: the general wording.
    }
    await _local.daily(
      id: dailyId,
      hour: time.hour,
      minute: time.minute,
      title: l.reminderDailyTitle,
      body: course == null
          ? l.reminderDailyBodyGeneric
          : l.reminderDailyBody(course),
      path: path ?? '/home',
    );
  }

  Future<void> _scheduleDeadlines(AppLocalizations l, DateTime now) async {
    final tasks = await ref.read(assessmentRepositoryProvider).tasks();
    final due = dueSoon(tasks, now);
    var id = _firstDeadlineId;
    for (final t in due) {
      final path = t.isQuiz
          ? '/course/${t.courseId}/quiz/${t.id}'
          : '/course/${t.courseId}/assignment/${t.id}';
      for (final (before, title) in [
        (const Duration(days: 1), l.reminderDueTomorrow(t.title)),
        (const Duration(hours: 1), l.reminderDueInHour(t.title)),
      ]) {
        final when = t.dueAt!.subtract(before);
        if (when.isAfter(now)) {
          await _local.at(
            id: id,
            when: when,
            title: title,
            body: t.courseTitle,
            path: path,
          );
        }
        id++;
      }
    }
  }

  /// Quizzes and assignments still to do, due later than now, nearest
  /// first.
  @visibleForTesting
  static List<LearnerTask> dueSoon(List<LearnerTask> tasks, DateTime now) =>
      (tasks
              .where(
                (t) =>
                    t.group == TaskGroup.todo &&
                    t.dueAt != null &&
                    t.dueAt!.isAfter(now),
              )
              .toList()
            ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!)))
          .take(maxItems)
          .toList();
}

final remindersProvider =
    NotifierProvider<RemindersController, ReminderSettings>(
      RemindersController.new,
    );
