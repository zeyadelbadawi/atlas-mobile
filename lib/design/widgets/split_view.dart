import 'package:flutter/material.dart';

import '../atlas_theme.dart';

/// Whether this screen is wide enough to show a list and the item it opens
/// side by side ([AtlasSize.splitFrom]: iPad landscape, 13" portrait, wide
/// Android tablets; never a phone, Slide Over or a narrow Split View pane).
bool isSplit(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AtlasSize.splitFrom;

/// Master/detail: [master] in a fixed column at the reading start, a hairline,
/// then [detail]. Below [AtlasSize.splitFrom] only [narrow] (or [detail]) is
/// shown, so phones keep their push-to-open flow.
class SplitView extends StatelessWidget {
  const SplitView({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = AtlasSize.masterWidth,
  });

  final Widget master;
  final Widget detail;
  final double masterWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: masterWidth, child: master),
        VerticalDivider(width: 1, thickness: 1, color: c.rule),
        Expanded(child: detail),
      ],
    );
  }
}
