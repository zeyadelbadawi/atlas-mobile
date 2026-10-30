import 'package:flutter/widgets.dart';

/// The direction of text that comes from the academy (a course title, a
/// description, an announcement), from its first strong letter. An English
/// paragraph in the Arabic app, or the reverse, then reads in its own
/// direction: its full stop and its "…" land where they belong. Null when
/// it matches the surrounding direction (nothing to change).
TextDirection? contentDirection(BuildContext context, String? text) {
  if (text == null) return null;
  final ambient = Directionality.of(context);
  for (final r in text.runes) {
    final TextDirection d;
    if (_rtl(r)) {
      d = TextDirection.rtl;
    } else if (_ltr(r)) {
      d = TextDirection.ltr;
    } else {
      continue;
    }
    return d == ambient ? null : d;
  }
  return null;
}

bool _rtl(int r) =>
    (r >= 0x0590 && r <= 0x08FF) ||
    (r >= 0xFB1D && r <= 0xFDFF) ||
    (r >= 0xFE70 && r <= 0xFEFF);

bool _ltr(int r) =>
    (r >= 0x41 && r <= 0x5A) ||
    (r >= 0x61 && r <= 0x7A) ||
    (r >= 0xC0 && r <= 0x24F) ||
    (r >= 0x370 && r <= 0x58F);
