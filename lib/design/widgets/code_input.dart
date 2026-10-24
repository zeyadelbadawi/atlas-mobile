import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atlas_theme.dart';

/// Six cells over one hidden text field, so iOS "From Messages/Mail" and
/// Android autofill fill the whole code. Always reads left to right. Pasting
/// or autofilling six digits calls [onCompleted].
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
    this.autofocus = true,
    this.semanticLabel = 'Code',
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool autofocus;
  final String semanticLabel;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final text = widget.controller.text;
    final digits = _localDigits(context, text);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          Semantics(
            label: widget.semanticLabel,
            value: text,
            textField: true,
            child: GestureDetector(
              onTap: () => _focus.requestFocus(),
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(child: _cell(c, a.type, i, text, digits)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(AtlasColors c, AtlasType t, int i, String text, String digits) {
    final focused =
        _focus.hasFocus &&
        i == text.length.clamp(0, widget.length - 1) &&
        text.length < widget.length;
    final filled = i < text.length;
    final border = widget.hasError
        ? c.danger
        : focused
        ? c.accent
        : Colors.transparent;
    return AnimatedContainer(
      duration: AtlasMotion.quick,
      curve: AtlasMotion.easeOut,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: focused ? c.raised : c.sunken,
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        border: Border.all(color: border, width: widget.hasError ? 1.5 : 2),
      ),
      child: filled
          ? Text(
              digits[i],
              style: t.title2.copyWith(
                color: widget.hasError ? c.danger : c.ink,
              ),
            )
          : focused
          ? Container(width: 2, height: 26, color: c.accent)
          : null,
    );
  }

  /// Shows Arabic-Indic digits in an Arabic UI; the value stays ASCII.
  String _localDigits(BuildContext context, String s) {
    if (Localizations.maybeLocaleOf(context)?.languageCode != 'ar') return s;
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return s.split('').map((d) => ar[int.tryParse(d) ?? 0]).join();
  }
}
