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
/// Fills from the reading start (right in Arabic). Completed = accent,
/// current = partly filled, upcoming = hairline.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.segments,
    this.height = 6,
    this.semanticLabel,
  });

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
                      color: c.rule,
                      child: Align(
                        alignment: rtl
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: segments[i].watched.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: ColoredBox(color: c.accent),
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
