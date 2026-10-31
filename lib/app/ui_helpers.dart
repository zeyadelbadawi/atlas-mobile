import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Separator for meta lines: the Arabic comma in Arabic (a middle dot
  /// reads as the digit zero there), a middle dot in English.
  /// Separator for meta lines ("course، 12 lessons"). Wrapped in invisible
  /// direction marks (RLM in Arabic, LRM in English) so a part written in
  /// the other script (an Arabic instructor in the English app) stays in
  /// its own place instead of pulling the numbers around it.
  String get sep => languageCode == 'ar' ? '\u200F، \u200F' : '\u200E · \u200E';

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

/// Content width: a readable column on a phone; on a tablet pages use the
/// room ([AtlasSize.wideWidth]) and forms stay comfortable ([form]).
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.form = false});
  final Widget child;
  final bool form;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: AtlasSize.contentWidth(
          MediaQuery.sizeOf(context).width,
          form: form,
        ),
      ),
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
    this.icon,
    this.subtitle,
  });

  final String title;
  final List<Widget> children;
  final bool showTitle;

  /// Drawn in a tonal tile above the title: what this step is about
  /// (a letter for an emailed code, a key for a new password).
  final IconData? icon;

  /// One line under the title, when the step needs it.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    var order = 0;
    Widget enter(Widget w) =>
        w is SizedBox ? w : Entrance(order: order++, child: w);
    return ScrollTitleScaffold(
      title: title,
      showAfter: icon != null ? 110 : 40,
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
            form: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTitle) ...[
                  if (icon != null) ...[
                    enter(
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: c.tonal,
                            borderRadius: BorderRadius.circular(AtlasRadius.lg),
                          ),
                          child: Icon(icon, color: c.accent, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: AtlasSpace.s16),
                  ],
                  enter(
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: a.type.title1.copyWith(color: c.ink),
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AtlasSpace.s8),
                    enter(
                      Text(
                        subtitle!,
                        style: a.type.body.copyWith(color: c.inkSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: AtlasSpace.s24),
                ],
                for (final w in children) enter(w),
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
