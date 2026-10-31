import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// One lesson in a [SegmentedProgress].
class ProgressSegment {
  const ProgressSegment({required this.minutes, this.watched = 0});

  /// The lesson's real length; sets the segment's width.
  final double minutes;

  /// 0..1. 1 = completed.
  final double watched;
}

/// One segment per lesson, its width proportional to the lesson's duration.
/// Fills from the reading start (right in Arabic) in the academy's colour.
/// Completed = filled,
/// current = partly filled, upcoming = hairline.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.segments,
    this.height = 6,
    this.semanticLabel,
    this.fill,
    this.track,
  });

  /// Fill and track colours; default to the academy colour on a hairline.
  /// On the academy's own cover, pass its readable ink instead.
  final Color? fill;
  final Color? track;

  final List<ProgressSegment> segments;
  final double height;

  /// e.g. "3 of 8 lessons, 38%". Defaults to the percentage.
  final String? semanticLabel;

  double get fraction {
    final total = segments.fold<double>(0, (s, e) => s + e.minutes);
    if (total == 0) return 0;
    final done = segments.fold<double>(0, (s, e) => s + e.minutes * e.watched);
    return done / total;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticLabel ?? '${(fraction * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  flex: (segments[i].minutes * 10).round().clamp(1, 1 << 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(height / 2),
                    child: ColoredBox(
                      color: track ?? c.rule,
                      child: Align(
                        alignment: rtl
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        // A change (a lesson completed) grows the fill;
                        // the first build shows it as is.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            end: segments[i].watched.clamp(0.0, 1.0),
                          ),
                          duration: still
                              ? Duration.zero
                              : const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, child) => FractionallySizedBox(
                            widthFactor: value,
                            heightFactor: 1,
                            child: child,
                          ),
                          child: ColoredBox(color: fill ?? c.academy),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
