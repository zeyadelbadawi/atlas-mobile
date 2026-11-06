// No word is ever split across two lines, on any screen, at the smallest
// phone width, with large text, in Arabic and English. A label that cannot
// fit must shrink, ellipsize or wrap between words, never mid-word
// ("Complete / d").
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design/golden_harness.dart';
import 'fake_catalog.dart';
import 'fake_learning.dart';
import 'screen_harness.dart';

const _course = FakeLearningRepository.courseId;

const List<String?> _signedIn = [
  '/home',
  '/courses',
  '/tasks',
  '/notifications',
  '/account',
  '/account/profile',
  '/account/security',
  '/account/notifications',
  '/account/privacy',
  '/account/devices',
  '/account/results',
  '/account/certificates',
  '/account/notes',
  '/announcements',
  '/catalog',
  '/catalog/free-algebra',
  '/course/$_course',
  '/course/$_course/lesson/l2',
  '/course/$_course/quiz/l3',
  '/course/$_course/assignment/l6',
  '/course/$_course/live/ls-next',
  '/legal/terms',
  '/about',
  '/catalog/free-algebra/reviews',
  '/course/$_course/live/ls-done',
  '/course/$_course/live/ls-now',
  '/announcements/a1',
];

const List<String?> _signedOut = [
  '/academy/sign-in',
  '/academy/register',
  '/academy/forgot',
];

String _where(RenderObject o) {
  if (!const bool.fromEnvironment('WHERE')) return '';
  final chain = <String>[];
  var e = o.debugCreator is DebugCreator
      ? (o.debugCreator as DebugCreator).element
      : null;
  e?.visitAncestorElements((a) {
    final n = a.widget.runtimeType.toString();
    if (!n.startsWith('_') && chain.length < 8) chain.add(n);
    return chain.length < 8;
  });
  return ' maxLines=${(o as RenderParagraph).maxLines} w=${o.size.width.toStringAsFixed(0)} in ${chain.join('<')}';
}

bool _isWordChar(String ch) => RegExp(r'[A-Za-z0-9؀-ۿ٠-٩]').hasMatch(ch);

/// "text → where it breaks" for every paragraph that splits a word.
List<String> brokenWords(WidgetTester t) {
  final found = <String>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph && o.hasSize && o.size.width > 0) {
      final text = o.text.toPlainText(includeSemanticsLabels: false);
      final painter = TextPainter(
        text: o.text,
        textDirection: o.textDirection,
        textAlign: o.textAlign,
        textScaler: o.textScaler,
        maxLines: o.maxLines,
        ellipsis: o.overflow == TextOverflow.ellipsis ? '…' : null,
        locale: o.locale,
        strutStyle: o.strutStyle,
        textWidthBasis: o.textWidthBasis,
        textHeightBehavior: o.textHeightBehavior,
      )..layout(maxWidth: o.size.width);
      final lines = painter.computeLineMetrics();
      for (var i = 1; i < lines.length; i++) {
        final y = lines[i].baseline - lines[i].ascent + 1;
        final start = painter
            .getPositionForOffset(
              Offset(
                o.textDirection == TextDirection.rtl ? o.size.width - 1 : 1,
                y,
              ),
            )
            .offset;
        final lineStart = painter
            .getLineBoundary(TextPosition(offset: start))
            .start;
        if (lineStart <= 0 || lineStart >= text.length) continue;
        if (_isWordChar(text[lineStart - 1]) && _isWordChar(text[lineStart])) {
          found.add(
            '"${text.replaceAll('\n', ' ')}" → "${text.substring(0, lineStart)}|${text.substring(lineStart)}"${_where(o)}',
          );
        }
      }
      painter.dispose();
    }
    o.visitChildren(visit);
  }

  visit(t.binding.rootElement!.renderObject!);
  return found;
}

void main() {
  setUpAll(loadGoldenFonts);

  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 1.3]) {
      for (final (session, paths) in [
        (AsSignedIn.new, _signedIn),
        (AsSignedOut.new, _signedOut),
        (AsNoAcademy.new, const <String?>[null]),
      ]) {
        for (final path in paths) {
          testWidgets('$language ×$scale $path: no word split across lines', (
            t,
          ) async {
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            await pumpScreen(
              t,
              session: session,
              language: language,
              path: path,
              size: const Size(320, 640),
              catalog: RatedCatalog(),
            );
            expect(brokenWords(t), isEmpty);
          });
        }
      }
    }
  }
}
