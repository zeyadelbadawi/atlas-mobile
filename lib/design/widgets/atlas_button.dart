import 'package:flutter/material.dart';

import '../atlas_theme.dart';
import 'pressable.dart';

enum AtlasButtonStyle { primary, tonal, plain, destructive }

/// Full-width action, 52pt, radius 14. `onPressed: null` disables it;
/// `loading` keeps the size and swaps the label for a spinner.
class AtlasButton extends StatelessWidget {
  const AtlasButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AtlasButtonStyle.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AtlasButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final enabled = onPressed != null && !loading;
    final disabled = onPressed == null;
    final (Color? bg, Color fg) = switch (style) {
      _ when disabled => (
        style == AtlasButtonStyle.plain ? null : c.rule,
        c.inkTertiary,
      ),
      AtlasButtonStyle.primary => (c.button, c.onButton),
      AtlasButtonStyle.tonal => (c.tonal, c.accent),
      AtlasButtonStyle.plain => (null, c.accent),
      AtlasButtonStyle.destructive => (c.sunken, c.danger),
    };
    final content = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AtlasSpace.s8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: a.type.button.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AtlasSize.button),
          child: Container(
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.s20,
              vertical: AtlasSpace.s12,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AtlasRadius.lg),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
