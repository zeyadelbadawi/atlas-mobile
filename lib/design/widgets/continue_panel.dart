import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../atlas_theme.dart';
import 'atlas_button.dart';
import 'bookmark.dart';
import 'pressable.dart';
import 'segmented_progress.dart';

/// Home's first element under the cover: where the student stopped. The
/// bookmark hangs from the top edge at the leading side; the lesson number
/// sits beside it in display numerals.
class ContinuePanel extends StatelessWidget {
  const ContinuePanel({
    super.key,
    required this.unitLabel,
    required this.lessonNumber,
    required this.lessonTitle,
    required this.courseLine,
    required this.segments,
    required this.timeLeft,
    required this.countLabel,
    required this.resumeLabel,
    required this.onResume,
    this.progressSemantics,
  });

  /// "الدرس" / "Lesson".
  final String unitLabel;

  /// Already localised ("١٢" / "12").
  final String lessonNumber;
  final String lessonTitle;
  final String courseLine;
  final List<ProgressSegment> segments;
  final String timeLeft;
  final String countLabel;
  final String resumeLabel;
  final VoidCallback onResume;
  final String? progressSemantics;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Pressable(
      onTap: onResume,
      scale: 0.99,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: BorderRadius.circular(AtlasRadius.xl),
              border: Border.all(color: c.rule),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 34),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        lessonNumber,
                        style: a.type.numeral.copyWith(color: c.ink),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unitLabel,
                        style: a.type.footnote.copyWith(color: c.inkSecondary),
                      ),
                    ],
                  ),
                ),
                Text(lessonTitle, style: a.type.title3.copyWith(color: c.ink)),
                Text(
                  courseLine,
                  style: a.type.subhead.copyWith(color: c.inkSecondary),
                ),
                const SizedBox(height: 18),
                SegmentedProgress(
                  segments: segments,
                  semanticLabel: progressSemantics,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      countLabel,
                      style: a.type.caption.copyWith(color: c.inkSecondary),
                    ),
                    const Spacer(),
                    Text(
                      timeLeft,
                      style: a.type.caption.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AtlasButton(
                  label: resumeLabel,
                  icon: LucideIcons.play,
                  onPressed: onResume,
                ),
              ],
            ),
          ),
          const PositionedDirectional(start: 20, top: -1, child: Bookmark()),
        ],
      ),
    );
  }
}
