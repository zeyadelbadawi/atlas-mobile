import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get languageCode => Localizations.localeOf(this).languageCode;

  /// List separator: the Arabic comma in Arabic (a middle dot reads as the
  /// digit zero there), a middle dot in English.
  String get sep => languageCode == 'ar' ? '، ' : ' · ';

  /// The backend labels devices in English ("Atlas app on iOS", "Chrome on
  /// Windows"); in Arabic only the connecting words are translated.
  String deviceLabel(String label) => languageCode != 'ar'
      ? label
      : label.replaceAll('Atlas app', 'تطبيق أطلس').replaceAll(' on ', ' على ');

  /// Latin digits → Arabic-Indic digits in an Arabic UI.
  String digits(String s) {
    if (languageCode != 'ar') return s;
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return s.replaceAllMapped(RegExp('[0-9]'), (m) => d[int.parse(m[0]!)]);
  }
}

/// The text to show for an API error, from the web's catalogue.
String errorText(WidgetRef ref, BuildContext context, Object error) =>
    ref.read(errorCatalogProvider).of(error, context.languageCode);

/// Phone and tablet: content keeps a readable width and centres on iPad.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AtlasSize.readingWidth),
      child: child,
    ),
  );
}

/// A pushed form screen: inline title bar, padded scrolling content.
class FormScreen extends StatelessWidget {
  const FormScreen({
    super.key,
    required this.title,
    required this.children,
    this.showTitle = true,
  });

  final String title;
  final List<Widget> children;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AtlasSpace.gutter,
            AtlasSpace.s8,
            AtlasSpace.gutter,
            AtlasSpace.s32,
          ),
          child: ReadableWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTitle) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: a.type.title1.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s20),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(BuildContext context, String value) {
  final v = value.trim();
  if (v.isEmpty) return context.l10n.validationEmailRequired;
  if (!_emailPattern.hasMatch(v)) return context.l10n.validationEmailInvalid;
  return null;
}

/// A native confirm dialog (Cupertino on iOS). True only when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirm,
  required String cancel,
  bool destructive = false,
}) async {
  final ios = Theme.of(context).platform == TargetPlatform.iOS;
  Widget action(BuildContext c, String label, bool value) => ios
      ? CupertinoDialogAction(
          isDefaultAction: value && !destructive,
          isDestructiveAction: value && destructive,
          onPressed: () => Navigator.pop(c, value),
          child: Text(label),
        )
      : TextButton(
          onPressed: () => Navigator.pop(c, value),
          child: Text(label),
        );
  final ok = await showAdaptiveDialog<bool>(
    context: context,
    builder: (c) => AlertDialog.adaptive(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [action(c, cancel, false), action(c, confirm, true)],
    ),
  );
  return ok == true;
}
