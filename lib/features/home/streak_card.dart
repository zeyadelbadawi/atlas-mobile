import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/streak.dart';
import '../../app/ui_helpers.dart';
import '../../core/clock.dart';
import '../../design/design.dart';

/// Days studied in a row, and the last seven days at a glance.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  /// The letters Arabic calendars use, Sunday first (DateTime.weekday % 7).
  static const _arabic = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final days = ref.watch(studyDaysProvider);
    final streak = ref.watch(streakProvider);
    final now = clockNow();
    final today = DateTime(now.year, now.month, now.day);
    final studiedToday = days.contains(StudyDays.day(today));
    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    String letter(DateTime d) => context.languageCode == 'ar'
        ? _arabic[d.weekday % 7]
        : DateFormat.E('en').format(d).substring(0, 2);

    return AtlasCard(
      key: const ValueKey('streak'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flame,
                size: 26,
                color: streak > 0 ? c.goldText : c.inkTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (streak > 0)
                      Text(
                        l.streakDays(streak, context.digits('$streak')),
                        style: a.type.title3.copyWith(color: c.ink),
                      ),
                    Text(
                      streak == 0
                          ? l.streakStart
                          : studiedToday
                          ? l.streakToday
                          : l.streakKeep,
                      style: a.type.subhead.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: l.streakWeek,
            child: Row(
              children: [
                for (final d in week)
                  Expanded(
                    child: Semantics(
                      label:
                          (days.contains(StudyDays.day(d))
                          ? l.streakDayDone
                          : l.streakDayNot)(
                            DateFormat.EEEE(context.languageCode).format(d),
                          ),
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            Text(
                              letter(d),
                              style: a.type.caption.copyWith(
                                color: d == today ? c.ink : c.inkTertiary,
                                fontWeight: d == today
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _Dot(
                              done: days.contains(StudyDays.day(d)),
                              today: d == today,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.today});
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? c.gold : c.sunken,
        border: today && !done ? Border.all(color: c.goldText, width: 2) : null,
      ),
      child: done ? Icon(LucideIcons.check, size: 15, color: c.onGold) : null,
    );
  }
}
