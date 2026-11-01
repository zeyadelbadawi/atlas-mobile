import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import 'providers.dart';

/// The days the learner studied: marked on this phone (a lesson finished or
/// read for a minute, a quiz or assignment sent) and joined with the days
/// the server saw on any phone or the website ([mergeServer]). Per account
/// and academy; the last [keep] days are kept.
class StudyDays extends Notifier<Set<String>> {
  static const prefix = 'study.days.';
  static const keep = 120;
  String? _key;

  @override
  Set<String> build() {
    final who = ref.watch(
      sessionProvider.select(
        (s) => s.status == SessionStatus.signedIn
            ? (s.academy?.id, s.user?['id'])
            : null,
      ),
    );
    _key = who == null || who.$1 == null || who.$2 == null
        ? null
        : '$prefix${who.$1}.${who.$2}';
    if (_key == null) return const {};
    return Set.unmodifiable(
      ref.read(sharedPreferencesProvider).getStringList(_key!) ?? const [],
    );
  }

  static String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Today counts as a study day.
  Future<void> markToday() async {
    final today = day(clockNow());
    if (state.contains(today)) return;
    await _add([today]);
  }

  /// Days the server knows the learner studied (local dates, `YYYY-MM-DD`).
  Future<void> mergeServer(Iterable<String> days) async {
    final valid = days.where(
      (d) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) && !state.contains(d),
    );
    if (valid.isNotEmpty) await _add(valid);
  }

  Future<void> _add(Iterable<String> more) async {
    final key = _key;
    if (key == null) return;
    final days = ({...state, ...more}.toList()..sort());
    final kept = days.length > keep ? days.sublist(days.length - keep) : days;
    state = Set.unmodifiable(kept);
    await ref.read(sharedPreferencesProvider).setStringList(key, kept);
  }
}

final studyDaysProvider = NotifierProvider<StudyDays, Set<String>>(
  StudyDays.new,
);

/// Days in a row up to today. A day not studied yet today does not break
/// it: the streak counts up to yesterday until the day is over.
@visibleForTesting
int streakOf(Set<String> days, DateTime now) {
  var d = DateTime(now.year, now.month, now.day);
  if (!days.contains(StudyDays.day(d))) d = d.subtract(const Duration(days: 1));
  var n = 0;
  while (days.contains(StudyDays.day(d))) {
    n++;
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}

final streakProvider = Provider<int>(
  (ref) => streakOf(ref.watch(studyDaysProvider), clockNow()),
);
