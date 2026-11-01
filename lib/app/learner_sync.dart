import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../core/clock.dart';
import 'learning_providers.dart';
import 'notes.dart';
import 'providers.dart';
import 'streak.dart';

/// The phone's IANA time zone (`Africa/Cairo`), or null when unknown.
final timeZoneNameProvider = Provider<Future<String?> Function()>(
  (_) => () async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      return null;
    }
  },
);

/// Brings the learner's notes and study days in step with the server: on
/// sign-in and when the app comes back to the front (at most every ten
/// minutes). Offline, or against a server without these, nothing changes.
class LearnerSync extends Notifier<void> {
  DateTime? _last;

  @override
  void build() {
    ref.listen(sessionProvider.select((s) => s.status), (_, status) {
      if (status == SessionStatus.signedIn) unawaited(run(force: true));
    });
    final life = AppLifecycleListener(onResume: () => unawaited(run()));
    ref.onDispose(life.dispose);
  }

  Future<void> run({bool force = false}) async {
    if (ref.read(sessionProvider).status != SessionStatus.signedIn) return;
    final now = clockNow();
    if (!force &&
        _last != null &&
        now.difference(_last!) < const Duration(minutes: 10)) {
      return;
    }
    _last = now;
    await Future.wait([_notes(), _days()]);
  }

  Future<void> _notes() async {
    try {
      await ref.read(notesProvider.notifier).sync();
    } on Object catch (e) {
      debugPrint('notes sync: $e');
    }
  }

  Future<void> _days() async {
    try {
      final zone = await ref.read(timeZoneNameProvider)();
      // Without the phone's zone the server's dates could be a day off.
      if (zone == null) return;
      final days = await ref.read(learningRepositoryProvider).studyDays(zone);
      await ref.read(studyDaysProvider.notifier).mergeServer(days);
    } on Object {
      // Offline, or a server without study days: the phone's days stand.
    }
  }
}

final learnerSyncProvider = NotifierProvider<LearnerSync, void>(
  LearnerSync.new,
);
