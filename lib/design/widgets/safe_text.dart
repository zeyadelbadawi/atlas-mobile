import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Text that wraps only between words. When a single word is wider than
/// the line (a big title on a small phone, large text settings), the text
/// shrinks just enough for that word to fit, instead of splitting it
/// ("Complete / d").
class SafeText extends StatelessWidget {
  const SafeText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  /// The font size [style] needs for its widest word to fit [maxWidth].
  static TextStyle fit(
    BuildContext context,
    String data,
    TextStyle style,
    double maxWidth, {
    TextDirection? textDirection,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0) return style;
    final scaler = MediaQuery.textScalerOf(context);
    final dir = textDirection ?? Directionality.of(context);
    var widest = 0.0;
    for (final word in data.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final p = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, p.width);
      p.dispose();
    }
    if (widest <= maxWidth) return style;
    // A hair under, so rounding never tips it back over.
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * maxWidth / widest * 0.97,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, box) => Text(
        data,
        style: fit(
          context,
          data,
          base,
          box.maxWidth,
          textDirection: textDirection,
        ),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// A short label that must stay on one line (a segment, a tab, a tile):
/// it shrinks to fit rather than wrapping.
class OneLine extends StatelessWidget {
  const OneLine(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.alignment = AlignmentDirectional.center,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
    ),
  );
}

/// The app's segmented control: labels stay on one line, shrinking a
/// little on a narrow phone instead of breaking a word.
class AtlasSegmented<T> extends StatelessWidget {
  const AtlasSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.selectedBackground,
    required this.selectedForeground,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color selectedBackground;
  final Color selectedForeground;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final (value, label) in segments)
        ButtonSegment<T>(value: value, label: OneLine(label), tooltip: label),
    ],
    selected: {selected},
    onSelectionChanged: (s) => onChanged(s.first),
    style: SegmentedButton.styleFrom(
      selectedBackgroundColor: selectedBackground,
      selectedForegroundColor: selectedForeground,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );
}
