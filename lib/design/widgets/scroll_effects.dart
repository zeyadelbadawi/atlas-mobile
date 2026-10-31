import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atlas_theme.dart';
import 'academy_logo.dart';

double _offset(ScrollController c) =>
    c.hasClients && c.positions.length == 1 ? c.offset : 0;

/// Moves its child at half the scroll speed and lets it fade a little, so
/// the content reads as rising over it. Still under Reduce Motion.
class ScrollParallax extends StatelessWidget {
  const ScrollParallax({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final y = _offset(controller).clamp(0.0, 480.0);
        return Transform.translate(
          offset: Offset(0, y * 0.5),
          child: Opacity(
            opacity: 1 - (y / 300).clamp(0.0, 1.0) * 0.45,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// A compact title bar (frosted paper, the academy's logo and name) that
/// eases in once the large cover has scrolled away, like an iOS large title
/// collapsing into the bar. It takes no taps until it shows.
class CompactTitleBar extends StatelessWidget {
  const CompactTitleBar({
    super.key,
    required this.controller,
    required this.showAfter,
    required this.title,
    this.logo,
  });

  final ScrollController controller;

  /// Scroll offset at which the bar starts to appear.
  final double showAfter;
  final String title;
  final ImageProvider? logo;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = ((_offset(controller) - showAfter) / 48).clamp(0.0, 1.0);
          if (t == 0) return const SizedBox.shrink();
          final bar = Opacity(opacity: t, child: child);
          return t < 0.5
              ? bar
              : AnnotatedRegion<SystemUiOverlayStyle>(
                  value: c.brightness == Brightness.light
                      ? SystemUiOverlayStyle.dark
                      : SystemUiOverlayStyle.light,
                  child: bar,
                );
        },
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.only(top: top),
              decoration: BoxDecoration(
                color: c.paper.withValues(alpha: 0.86),
                border: Border(bottom: BorderSide(color: c.rule)),
              ),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AcademyLogo(academyName: title, image: logo, size: 26),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: a.type.headline.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back, over a full-bleed cover: a round paper chip that reads on any
/// cover colour and on the compact bar once it has slid in. Hidden on a
/// screen that cannot go back.
class CoverBackButton extends StatelessWidget {
  const CoverBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!(ModalRoute.of(context)?.canPop ?? false)) {
      return const SizedBox.shrink();
    }
    final c = context.atlas.colors;
    return PositionedDirectional(
      top: MediaQuery.paddingOf(context).top + 2,
      start: 8,
      child: Material(
        color: c.raised.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 0,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          color: c.ink,
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}
