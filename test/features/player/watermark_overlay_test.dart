import 'dart:math' as math;

import 'package:atlas_mobile/features/player/watermark_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 450),
      disableAnimations: reduceMotion,
    ),
    child: SizedBox(width: 800, height: 450, child: child),
  ),
);

void main() {
  testWidgets(
    'shows the code and the masked identity, ignores touches, hidden from a11y',
    (t) async {
      await t.pumpWidget(
        _host(
          const WatermarkOverlay(
            code: '6SG7A-QKN29',
            secondary: 'g•••@example.test',
          ),
        ),
      );
      expect(find.text('6SG7A-QKN29 · g•••@example.test'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('forensic-watermark')),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      final semantics = t.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('6SG7A')), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('the label jumps somewhere else within 20–45 s', (t) async {
    await t.pumpWidget(
      _host(WatermarkOverlay(code: 'ABCDE-FGHJK', random: math.Random(7))),
    );
    final label = find.byKey(const ValueKey('forensic-watermark-label'));
    final before = t.getTopLeft(label);

    await t.pump(const Duration(seconds: 19));
    expect(t.getTopLeft(label), before, reason: 'not before 20 s');

    await t.pump(const Duration(seconds: 27)); // past 45 s
    await t.pump(const Duration(milliseconds: 400)); // past the fade
    expect(t.getTopLeft(label), isNot(before));
  });

  testWidgets('reduce motion: still drawn, no drift animation running', (
    t,
  ) async {
    await t.pumpWidget(
      _host(const WatermarkOverlay(code: 'ABCDE-FGHJK'), reduceMotion: true),
    );
    expect(
      find.byKey(const ValueKey('forensic-watermark-pattern')),
      findsOneWidget,
    );
    await t.pump(const Duration(seconds: 1));
    expect(t.binding.transientCallbackCount, 0, reason: 'no ticker is running');
  });
}
