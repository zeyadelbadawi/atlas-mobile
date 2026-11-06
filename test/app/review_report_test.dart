// Course reviews are content other learners publish: each can be reported
// (by email, with what identifies it) or hidden, and goes from the list
// at once and for good on this phone.
import 'package:atlas_mobile/features/catalog/reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_catalog.dart';
import 'screen_harness.dart';
import '../design/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  Future<void> open(WidgetTester t, {Map<String, Object> prefs = const {}}) =>
      pumpScreen(
        t,
        session: AsSignedIn.new,
        language: 'en',
        path: '/catalog/free-algebra/reviews',
        catalog: RatedCatalog(),
        prefs: prefs,
      ).then((_) => t.pump(const Duration(seconds: 1)));

  testWidgets('hide: the review goes at once and stays hidden', (t) async {
    await open(t);
    expect(find.byType(ReviewTile), findsNWidgets(3));
    await t.tap(find.byKey(const ValueKey('review-actions-r1')));
    await t.pumpAndSettle();
    await t.tap(find.text('Hide this review'));
    await t.pumpAndSettle();
    expect(find.byType(ReviewTile), findsNWidgets(2));
    expect(find.byKey(const ValueKey('review-actions-r1')), findsNothing);
    expect(find.text('Review hidden.'), findsOneWidget);
  });

  testWidgets('report: says so and hides it', (t) async {
    await open(t);
    await t.tap(find.byKey(const ValueKey('review-actions-r2')));
    await t.pumpAndSettle();
    expect(find.textContaining('within 24 hours'), findsOneWidget);
    await t.tap(find.text('Report this review'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-actions-r2')), findsNothing);
    expect(find.textContaining('Your report is ready'), findsOneWidget);
  });

  testWidgets('a review hidden before stays hidden', (t) async {
    await open(
      t,
      prefs: {
        HiddenReviews.key: <String>['r1', 'r3'],
      },
    );
    expect(find.byType(ReviewTile), findsOneWidget);
  });
}
