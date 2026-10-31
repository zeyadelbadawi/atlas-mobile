/// Text made comparable for search, the way people type Arabic: without
/// diacritics or tatweel, with the alef, yaa and taa marbuta forms folded
/// (أ إ آ ٱ → ا, ى → ي, ة → ه), and English lower-cased.
String searchable(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    // Harakat, superscript alef, tatweel.
    if ((r >= 0x064B && r <= 0x065F) || r == 0x0670 || r == 0x0640) continue;
    out.writeCharCode(switch (r) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627,
      0x0649 => 0x064A,
      0x0629 => 0x0647,
      _ => r,
    });
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Every word of [query] is in [text] (any order).
bool searchMatches(String text, String query) {
  final t = searchable(text);
  return searchable(query).split(' ').every(t.contains);
}
