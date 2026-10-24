import 'package:flutter/animation.dart';

/// Spacing, radii and sizes. Mirrors the `Size` collection in Figma.
abstract final class AtlasSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Screen side margin on phones.
  static const double gutter = 20;
}

abstract final class AtlasRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 22;
}

abstract final class AtlasSize {
  /// iOS minimum touch target (Android's 48dp is met by padding).
  static const double touch = 44;
  static const double button = 52;
  static const double field = 52;
  static const double hairline = 1;

  /// Content stops growing past this on iPad and wide windows.
  static const double readingWidth = 560;
}

/// Motion from the Emil Kowalski guidance: short, ease-out, interruptible.
abstract final class AtlasMotion {
  /// Strong ease-out for things entering or responding to touch.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// On-screen movement (the bookmark sliding to the next lesson).
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS-like sheet curve.
  static const Curve sheet = Cubic(0.32, 0.72, 0, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration bookmark = Duration(milliseconds: 280);

  static const double pressScale = 0.97;
}
