import 'package:atlas_mobile/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fill shows as is on first build and grows when progress changes.
void main() {
  Widget bar(double watched, {bool still = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: buildAtlasTheme(
          palette: AcademyPalette.atlas,
          brightness: Brightness.light,
          languageCode: 'en',
        ),
        child: Center(
          child: SizedBox(
            width: 200,
            child: SegmentedProgress(
              segments: [ProgressSegment(minutes: 10, watched: watched)],
            ),
          ),
        ),
      ),
    ),
  );

  double fill(WidgetTester t) => t
      .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .widthFactor!;

  testWidgets('first build is not animated', (t) async {
    await t.pumpWidget(bar(0.5));
    expect(fill(t), 0.5);
  });

  testWidgets('a change grows the fill', (t) async {
    await t.pumpWidget(bar(0.2));
    await t.pumpWidget(bar(1));
    await t.pump(const Duration(milliseconds: 100));
    expect(fill(t), inExclusiveRange(0.2, 1));
    await t.pump(const Duration(milliseconds: 400));
    expect(fill(t), 1);
  });

  testWidgets('reduced motion jumps', (t) async {
    await t.pumpWidget(bar(0.2, still: true));
    await t.pumpWidget(bar(1, still: true));
    await t.pump();
    expect(fill(t), 1);
  });
}
