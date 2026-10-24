import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atlas_theme.dart';
import 'academy_logo.dart';

/// The handout cover: a full-bleed band in the academy colour under the
/// status bar. One message per band.
///
/// - [CoverBand.home]: logo + academy name, greeting as large title. Leave
///   [overlap] for the Continue panel that sits over its lower edge.
/// - [CoverBand.compact]: sign-in screens. Larger logo, academy host.
class CoverBand extends StatelessWidget {
  const CoverBand.home({
    super.key,
    required this.academyName,
    required String greeting,
    this.logo,
    this.overlap = 40,
    this.trailing,
  }) : title = greeting,
       subtitle = null,
       _compact = false;

  const CoverBand.compact({
    super.key,
    required this.academyName,
    String? host,
    this.logo,
    this.trailing,
  }) : title = null,
       subtitle = host,
       overlap = 0,
       _compact = true;

  final String academyName;
  final String? title;
  final String? subtitle;
  final ImageProvider? logo;
  final double overlap;

  /// Optional control at the trailing top (e.g. "Change academy").
  final Widget? trailing;
  final bool _compact;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final top = MediaQuery.paddingOf(context).top;
    final overlay = c.coverIsLight
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        width: double.infinity,
        color: c.cover,
        padding: EdgeInsetsDirectional.only(
          start: AtlasSpace.gutter,
          end: AtlasSpace.gutter,
          top: top + (_compact ? 16 : 8),
          bottom: (_compact ? 28 : 24) + overlap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AcademyLogo(
                  academyName: academyName,
                  image: logo,
                  size: _compact ? 56 : 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    academyName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (_compact ? a.type.title2 : a.type.headline)
                        .copyWith(color: c.onCover),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (title != null) ...[
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text(
                  title!,
                  style: a.type.largeTitle.copyWith(color: c.onCover),
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textDirection: TextDirection.ltr,
                style: a.type.subhead.copyWith(
                  color: c.onCover.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
