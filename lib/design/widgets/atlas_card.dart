import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// A raised surface: white (dark: card) with a hairline and the soft Atlas
/// shadow. Holds forms and grouped rows; never nested in another card.
class AtlasCard extends StatelessWidget {
  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtlasSpace.s20),
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Clips the child to the rounded corners (rows that paint to the edge).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    final radius = BorderRadius.circular(AtlasRadius.xl);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: radius,
        border: Border.all(color: c.rule),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: clip ? ClipRRect(borderRadius: radius, child: child) : child,
    );
  }
}
