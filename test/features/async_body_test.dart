import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/design/design.dart';
import 'package:atlas_mobile/features/learning/learning_ui.dart';
import 'package:atlas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _offline = FutureProvider<String>(
  (ref) async => throw const AtlasApiException(
    kind: 'network',
    messageKey: 'errors.network.offline',
    retryable: true,
  ),
);

void main() {
  testWidgets('a failed load shows its error at once, while Riverpod retries', (
    t,
  ) async {
    final container = ProviderContainer();
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAtlasTheme(
            palette: AcademyPalette.atlas,
            brightness: Brightness.light,
            languageCode: 'en',
          ),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => AsyncBody<String>(
                value: ref.watch(_offline),
                onRetry: () => ref.invalidate(_offline),
                data: Text.new,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 250)); // the loader fades out
    // Still retrying in the background...
    expect(container.read(_offline).isLoading, isTrue);
    // ...but the learner already sees why, and can retry.
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await t.pumpWidget(const SizedBox());
    container.dispose();
  });
}
