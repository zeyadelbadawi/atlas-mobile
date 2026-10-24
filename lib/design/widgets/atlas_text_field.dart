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
    this.inputFormatters,
    this.focusNode,
  });

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
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  State<AtlasTextField> createState() => _AtlasTextFieldState();
}

class _AtlasTextFieldState extends State<AtlasTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
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
          AnimatedContainer(
            duration: AtlasMotion.quick,
            curve: AtlasMotion.easeOut,
            constraints: const BoxConstraints(minHeight: AtlasSize.field),
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            decoration: BoxDecoration(
              color: ring != null ? c.raised : c.sunken,
              borderRadius: BorderRadius.circular(AtlasRadius.md),
              border: Border.all(color: ring ?? Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  widget.prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
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
                    textDirection: widget.ltrValue ? TextDirection.ltr : null,
                    textAlign:
                        widget.ltrValue &&
                            Directionality.of(context) == TextDirection.rtl
                        ? TextAlign.right
                        : TextAlign.start,
                    style: a.type.body.copyWith(color: c.ink),
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: a.type.body.copyWith(color: c.inkTertiary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                if (widget.password)
                  IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
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
