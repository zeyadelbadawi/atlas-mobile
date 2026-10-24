import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../atlas_theme.dart';

/// Consent and preference rows. Never pre-checked for consent. The whole row
/// toggles; links inside [label] (TextSpans with recognizers) open documents
/// without toggling.
class CheckboxRow extends StatelessWidget {
  const CheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final InlineSpan label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Semantics(
        checked: value,
        label: semanticLabel,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AtlasSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AtlasMotion.quick,
                    curve: AtlasMotion.easeOut,
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: value ? c.button : c.raised,
                      borderRadius: BorderRadius.circular(AtlasRadius.sm),
                      border: value
                          ? null
                          : Border.all(color: c.ruleStrong, width: 1.5),
                    ),
                    child: value
                        ? Icon(LucideIcons.check, size: 18, color: c.onButton)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      label,
                      style: a.type.subhead.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
