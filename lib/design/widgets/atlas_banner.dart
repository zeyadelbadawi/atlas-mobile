import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../atlas_theme.dart';

enum AtlasBannerKind { info, error, success }

/// Inline status inside a form or screen. Errors say what happened and what
/// to do next. Announced to screen readers.
class AtlasBanner extends StatelessWidget {
  const AtlasBanner({
    super.key,
    required this.message,
    this.kind = AtlasBannerKind.info,
  });

  final String message;
  final AtlasBannerKind kind;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final (IconData icon, Color fg, Color bg) = switch (kind) {
      AtlasBannerKind.info => (LucideIcons.info, c.accent, c.tonal),
      AtlasBannerKind.error => (LucideIcons.circleAlert, c.danger, c.sunken),
      AtlasBannerKind.success => (LucideIcons.check, c.success, c.sunken),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AtlasRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: a.type.subhead.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
