import 'package:flutter/material.dart';

import '../../core/clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';

/// Default weight for a lesson whose duration the academy did not set, so
/// unknown lengths still read as lessons rather than slivers.
const _unknownMinutes = 10.0;

/// Duration-weighted segments for a course (the signature progress line).
List<ProgressSegment> segmentsFor(
  CourseSequence s, {
  double currentWatched = 0.15,
}) => [
  for (final i in s.items)
    ProgressSegment(
      minutes: i.durationSeconds != null && i.durationSeconds! > 0
          ? i.durationSeconds! / 60
          : _unknownMinutes,
      watched: i.isDone
          ? 1
          : i.id == s.continueItemId
          ? currentWatched
          : 0,
    ),
];

/// Equal segments from counts (lists, where the sequence isn't loaded).
List<ProgressSegment> segmentsFromCounts(int done, int total) {
  if (total <= 0) return const [];
  const maxSegments = 24;
  final n = total.clamp(1, maxSegments);
  final doneScaled = (done / total * n);
  return [
    for (var i = 0; i < n; i++)
      ProgressSegment(
        minutes: 1,
        watched: (doneScaled - i).clamp(0, 1).toDouble(),
      ),
  ];
}

/// Minutes of the remaining items, when the academy set durations.
int? minutesLeft(CourseSequence s) {
  final rest = s.items.where((i) => !i.isDone).toList();
  if (rest.isEmpty || rest.any((i) => i.durationSeconds == null)) return null;
  return (rest.fold<int>(0, (a, i) => a + i.durationSeconds!) / 60).ceil();
}

IconData itemIcon(String type) => switch (type) {
  'quiz' => LucideIcons.listChecks,
  'assignment' => LucideIcons.fileText,
  'live_session' => LucideIcons.video,
  _ => LucideIcons.bookOpen,
};

String unitLabel(BuildContext context, String type) => switch (type) {
  'quiz' => context.l10n.unitQuiz,
  'assignment' => context.l10n.unitAssignment,
  'live_session' => context.l10n.unitLive,
  _ => context.l10n.unitLesson,
};

String? lockText(BuildContext context, SequenceItem i) {
  if (!i.isLocked) return null;
  final l = context.l10n;
  return switch (i.lockReason) {
    'scheduled' => l.lockScheduled(
      i.availableAt == null ? '' : shortDate(context, i.availableAt!),
    ),
    'notStarted' => l.lockNotStarted,
    'accessEnded' => l.lockAccessEnded,
    'quizNotPassed' => l.lockQuizNotPassed,
    _ => l.lockPrevious,
  };
}

String shortDate(BuildContext context, DateTime d) =>
    context.digits(DateFormat.MMMd(context.languageCode).format(d));

String timeOfDay(BuildContext context, DateTime d) =>
    context.digits(DateFormat.jm(context.languageCode).format(d));

String weekdayShort(BuildContext context, DateTime d) =>
    DateFormat.EEEE(context.languageCode).format(d);

String relative(BuildContext context, DateTime d) {
  final now = clockNow();
  final days = DateTime(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days.abs() < 7) {
    return context.digits(
      '${weekdayShort(context, d)} ${DateFormat.jm(context.languageCode).format(d)}',
    );
  }
  return shortDate(context, d);
}

/// Loading, error with retry, or data — the one pattern every list uses.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: SizedBox.square(
            dimension: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (e, _) => LoadError(onRetry: onRetry),
    );
  }
}

/// A failed load: what went wrong (or the generic text) and Retry.
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AtlasSpace.gutter),
    child: Column(
      children: [
        AtlasBanner(
          kind: AtlasBannerKind.error,
          message: message ?? context.l10n.loadFailed,
        ),
        const SizedBox(height: AtlasSpace.s12),
        AtlasButton(
          label: context.l10n.commonRetry,
          style: AtlasButtonStyle.tonal,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
