import 'package:flutter/material.dart';

import '../atlas_theme.dart';
import 'atlas_button.dart';
import 'entrance.dart';

/// Nothing to show yet, a failed load or no connection: one shape
/// everywhere. A tinted disc with the icon, a title, an optional line of
/// explanation and an optional action, centred in the space it is given.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Errors: the disc and icon in the danger colour.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final tint = danger ? c.danger : c.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AtlasSpace.s40,
        horizontal: AtlasSpace.s16,
      ),
      child: Entrance(
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: danger ? c.danger.withValues(alpha: 0.1) : c.tonal,
                ),
                child: Icon(icon, size: 32, color: tint),
              ),
            ),
            const SizedBox(height: AtlasSpace.s16),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: a.type.title3.copyWith(color: c.ink),
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: AtlasSpace.s8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: a.type.subhead.copyWith(color: c.inkSecondary),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AtlasSpace.s20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: AtlasButton(
                  label: actionLabel!,
                  style: AtlasButtonStyle.tonal,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
