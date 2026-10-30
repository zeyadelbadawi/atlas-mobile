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
  /// Minimum touch target: Android's 48dp (also above iOS's 44pt).
  static const double touch = 48;
  static const double button = 52;
  static const double field = 52;
  static const double hairline = 1;

  /// Content stops growing past this on iPad and wide windows.
  static const double readingWidth = 560;

  /// On a tablet: pages use the room (two columns on Home), forms stay a
  /// comfortable width.
  static const double wideWidth = 960;
  static const double formWidth = 600;

  /// Text is a little larger on tablets (on top of the user's own size).
  static const double tabletTextScale = 1.1;

  /// The page's content width: [readingWidth] on a phone, [wideWidth] (or
  /// [formWidth] for a form) from [sidebarFrom].
  static double contentWidth(double screenWidth, {bool form = false}) =>
      screenWidth < sidebarFrom
      ? readingWidth
      : form
      ? formWidth
      : wideWidth;

  /// From this width (iPad, Android tablets, a wide Split View pane) the
  /// tabs become a sidebar. Narrower (phones, Slide Over, a narrow Split
  /// View pane) keeps the bottom tab bar.
  static const double sidebarFrom = 700;

  /// iPadOS keeps the floating tab bar on narrower iPads (mini, 11" in
  /// portrait) and shows the sidebar from here.
  static const double iosSidebarFrom = 900;

  /// From this width a list and the item it opens sit side by side
  /// (master/detail): the course outline beside the lesson, the account
  /// menu beside the setting.
  static const double splitFrom = 1000;

  static const double sidebarWidth = 260;
  static const double masterWidth = 340;
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
