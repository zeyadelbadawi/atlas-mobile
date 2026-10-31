@Tags(['shots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';

/// A picture of the home-screen widget's design for review (the real one
/// is native: android/app/src/main/res/layout/widget_continue.xml and
/// ios/AtlasWidget/AtlasWidget.swift). Same texts, sizes and colours.
final _label = Platform.environment['SHOTS'];

class _Tokens {
  const _Tokens(this.dark);
  final bool dark;
  Color get surface => dark ? const Color(0xFF161B27) : Colors.white;
  Color get ink => dark ? const Color(0xFFECEEF3) : const Color(0xFF141A29);
  Color get ink2 => dark ? const Color(0xFF9CA3B4) : const Color(0xFF5C657A);
  Color get accent => dark ? const Color(0xFF709DFF) : const Color(0xFF1B398D);
  Color get gold => dark ? const Color(0xFFF0BF4C) : const Color(0xFF8A5A00);
  Color get track => dark ? const Color(0xFF1C2A4F) : const Color(0xFFE8EDFA);
}

Widget _widget(_Tokens t, {double w = 340, double h = 170}) => Container(
  width: w,
  height: h,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: t.surface,
    borderRadius: BorderRadius.circular(22),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'متابعة التعلّم',
              style: TextStyle(
                fontFamily: testBodyFamily,
                fontFamilyFallback: testBodyFallback,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.accent,
              ),
            ),
          ),
          Text(
            'أكاديمية المنارة',
            style: TextStyle(
              fontFamily: testBodyFamily,
              fontFamilyFallback: testBodyFallback,
              fontSize: 12,
              color: t.ink2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'التفاضل والتكامل',
        maxLines: 2,
        style: TextStyle(
          fontFamily: testBodyFamily,
          fontFamilyFallback: testBodyFallback,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: t.ink,
        ),
      ),
      Text(
        'التالي: النهايات من جهة واحدة',
        maxLines: 1,
        style: TextStyle(
          fontFamily: testBodyFamily,
          fontFamilyFallback: testBodyFallback,
          fontSize: 13,
          color: t.ink2,
        ),
      ),
      const Spacer(),
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.29,
                minHeight: 6,
                color: const Color(0xFFE0A424),
                backgroundColor: t.track,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'تم ٢٩٪',
            style: TextStyle(
              fontFamily: testBodyFamily,
              fontFamilyFallback: testBodyFallback,
              fontSize: 12,
              color: t.ink2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'التسليم الثلاثاء ٨:٠٠ م: واجب الاتصال',
        maxLines: 1,
        style: TextStyle(
          fontFamily: testBodyFamily,
          fontFamilyFallback: testBodyFallback,
          fontSize: 12,
          color: t.gold,
        ),
      ),
    ],
  ),
);

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('widget_preview', (t) async {
    await setDevice(t, const Size(393, 520));
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C8BD8), Color(0xFF2B3F7A)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _widget(const _Tokens(false)),
              const SizedBox(height: 24),
              _widget(const _Tokens(true)),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    final dir = 'build/ux_shots/$_label';
    await t.runAsync(() async {
      final image = await captureImage(t.element(find.byType(Directionality)));
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/widget_preview.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }, skip: _label == null);
}
