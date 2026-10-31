import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../atlas_theme.dart';

/// Label above, 52pt field on sunken, radius 10. Focused: raised with a 2pt
/// accent ring. Error: 2pt danger ring and a message that names the fix.
///
/// [ltrValue] keeps emails, phones and passwords left-to-right inside an
/// Arabic layout.
class AtlasTextField extends StatefulWidget {
  const AtlasTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.password = false,
    this.ltrValue = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.focusNode,
    this.showPasswordLabel = 'Show password',
    this.hidePasswordLabel = 'Hide password',
  });

  final String showPasswordLabel;
  final String hidePasswordLabel;

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;
  final bool password;
  final bool ltrValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Widget? prefix;

  /// Fixed text after the value, e.g. the domain the learner does not
  /// have to type.
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  State<AtlasTextField> createState() => _AtlasTextFieldState();
}

class _AtlasTextFieldState extends State<AtlasTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _obscured = true;

  /// Set once the field has been given a suffix; see the row below.
  bool _suffixMode = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    widget.controller?.addListener(_onText);
  }

  void _onFocus() => setState(() {});

  // With a suffix the field hugs its text, so it is redrawn as it changes.
  void _onText() {
    if (_suffixMode) setState(() {});
  }

  /// The width the value (or the hint, while empty) needs, so a suffix
  /// sits right after it: "ziadd" + ".atlass.dpdns.org".
  double _valueWidth(BuildContext context, TextStyle style) {
    final text = widget.controller?.text ?? '';
    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? (widget.hint ?? '') : text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w + 4; // room for the cursor
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onText);
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final focused = _focus.hasFocus;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final ring = hasError ? c.danger : (focused ? c.accent : null);
    final message = hasError ? widget.error : widget.helper;
    _suffixMode |= widget.suffix != null;
    final Widget field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      obscureText: widget.password && _obscured,
      enableSuggestions: !widget.password,
      autocorrect: false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      textAlign: TextAlign.start,
      style: a.type.body.copyWith(color: c.ink),
      cursorColor: c.accent,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.hint,
        hintStyle: a.type.body.copyWith(color: c.inkTertiary),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: a.type.footnote.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: 6),
          // A tap anywhere on the box (also beside a short value) types.
          GestureDetector(
            excludeFromSemantics: true,
            onTap: widget.enabled ? _focus.requestFocus : null,
            child: AnimatedContainer(
              duration: AtlasMotion.quick,
              curve: AtlasMotion.easeOut,
              constraints: const BoxConstraints(minHeight: AtlasSize.field),
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              decoration: BoxDecoration(
                color: ring != null ? c.raised : c.sunken,
                borderRadius: BorderRadius.circular(AtlasRadius.md),
                border: Border.all(color: ring ?? Colors.transparent, width: 2),
              ),
              child: Directionality(
                textDirection: widget.ltrValue
                    ? TextDirection.ltr
                    : Directionality.of(context),
                child: Row(
                  children: [
                    if (widget.prefix != null) ...[
                      widget.prefix!,
                      const SizedBox(width: 8),
                    ],
                    if (!_suffixMode)
                      Expanded(child: field)
                    else ...[
                      // Once a field has had a suffix it keeps this one
                      // structure, so the input is never rebuilt (and the
                      // keyboard never drops) as the suffix comes and goes.
                      // With a suffix the input takes what its text needs,
                      // nearly all the row if it must; without, all of it.
                      Flexible(
                        flex: 100,
                        child: SizedBox(
                          width: widget.suffix == null
                              ? double.infinity
                              : _valueWidth(context, a.type.body),
                          child: field,
                        ),
                      ),
                      widget.suffix ?? const SizedBox.shrink(),
                      const Spacer(),
                    ],
                    if (widget.password)
                      IconButton(
                        onPressed: () => setState(() => _obscured = !_obscured),
                        tooltip: _obscured
                            ? widget.showPasswordLabel
                            : widget.hidePasswordLabel,
                        icon: Icon(
                          _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 22,
                          color: c.inkSecondary,
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: hasError,
              child: Text(
                message,
                style: a.type.footnote.copyWith(
                  color: hasError ? c.danger : c.inkTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
