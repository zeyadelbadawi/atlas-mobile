import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/streak.dart';
import '../../app/ui_helpers.dart';
import '../../core/clock.dart';
import '../../design/design.dart';

/// Days studied in a row, this week at a glance, and the weekly goal.
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
    // The last seven days, today last: the days behind the streak, and the
    // window the weekly goal counts (no reset on the first day of a week).
    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final goal = ref.watch(weeklyGoalProvider);
    final doneThisWeek = week
        .where((d) => days.contains(StudyDays.day(d)))
        .length;
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
          const SizedBox(height: 12),
          _GoalLine(goal: goal, done: doneThisWeek),
        ],
      ),
    );
  }
}

/// "Set a weekly goal", or how far this week has got towards it.
class _GoalLine extends ConsumerWidget {
  const _GoalLine({required this.goal, required this.done});
  final int? goal;
  final int done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final g = goal;
    if (g == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('goal-set'),
          onPressed: () => pickWeeklyGoal(context, ref),
          icon: const Icon(LucideIcons.target, size: 18),
          label: Text(l.goalSet),
          style: TextButton.styleFrom(
            foregroundColor: c.accent,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: a.type.subhead.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    final reached = done >= g;
    return Row(
      key: const ValueKey('goal-line'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reached
                    ? l.goalReached
                    : l.goalProgress(
                        context.digits('${done.clamp(0, g)}'),
                        context.digits('$g'),
                      ),
                style: a.type.subhead.copyWith(
                  color: reached ? c.goldText : c.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (done / g).clamp(0, 1).toDouble()),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: c.sunken,
                    color: c.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l.goalEdit,
          onPressed: () => pickWeeklyGoal(context, ref),
          icon: Icon(LucideIcons.pencil, size: 18, color: c.inkSecondary),
        ),
      ],
    );
  }
}

/// Days a week to aim for: 1 to 7, or no goal.
Future<void> pickWeeklyGoal(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final current = ref.read(weeklyGoalProvider);
  final picked = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (s) {
      final a = s.atlas;
      final c = a.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.goalSheetTitle,
                style: a.type.title3.copyWith(color: c.ink),
              ),
              const SizedBox(height: 4),
              Text(
                l.goalSheetBody,
                style: a.type.subhead.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    ChoiceChip(
                      key: ValueKey('goal-$d'),
                      label: SizedBox(
                        width: 22,
                        child: Text(
                          s.digits('$d'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: current == d,
                      showCheckmark: false,
                      onSelected: (_) => Navigator.pop(s, d),
                    ),
                ],
              ),
              if (current != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => Navigator.pop(s, 0),
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    child: Text(l.goalOff),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (picked == null) return;
  await ref.read(weeklyGoalProvider.notifier).set(picked == 0 ? null : picked);
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
