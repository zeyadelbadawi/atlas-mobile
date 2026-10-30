import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../atlas_theme.dart';
import 'academy_logo.dart';
import 'pressable.dart';
import 'segmented_progress.dart';

/// Groups separate by type and space, not boxes: 28 above, 6 below.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: a.type.title3.copyWith(color: a.colors.ink),
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: a.colors.accent,
                textStyle: a.type.subhead,
                minimumSize: const Size(AtlasSize.touch, AtlasSize.touch),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// The forward chevron, mirrored in RTL.
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({super.key, this.size = 18, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    LucideIcons.chevronRight,
    size: size,
    color: color ?? context.atlas.colors.inkTertiary,
    textDirection: Directionality.of(context),
    applyTextScaling: true,
  );
}

/// An upcoming quiz or assignment. [changed] marks a moved deadline until
/// the row is opened.
class DueRow extends StatelessWidget {
  const DueRow({
    super.key,
    required this.day,
    required this.weekday,
    required this.title,
    required this.meta,
    required this.icon,
    this.changed = false,
    this.onTap,
  });

  final String day;
  final String weekday;
  final String title;
  final String meta;
  final IconData icon;
  final bool changed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(day, style: a.type.title2.copyWith(color: c.ink)),
                    Text(
                      weekday,
                      style: a.type.caption.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: a.type.headline.copyWith(color: c.ink),
                          ),
                        ),
                        if (changed) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(icon, size: 16, color: c.inkSecondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            meta,
                            style: a.type.footnote.copyWith(
                              color: changed ? c.warning : c.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ForwardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Booklet-ratio course cover. Without an image: the academy colour with the
/// unit/number set large, like a handout cover.
class CourseCover extends StatelessWidget {
  const CourseCover({
    super.key,
    this.image,
    this.kicker,
    this.mark,
    this.width = 64,
  });

  final ImageProvider? image;
  final String? kicker;
  final String? mark;
  final double width;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final h = width * 84 / 64;
    // A fixed-size graphic, hidden from screen readers: its text stays at
    // the designed size whatever the system text size.
    return MediaQuery.withNoTextScaling(
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: image == null ? c.cover : c.sunken,
            borderRadius: BorderRadius.circular(AtlasRadius.sm),
          ),
          child: image != null
              ? Image(image: image!, fit: BoxFit.cover)
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (kicker != null)
                        Text(
                          kicker!,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: a.type.caption.copyWith(
                            color: c.onCover.withValues(alpha: 0.75),
                          ),
                        ),
                      Text(
                        mark ?? '',
                        maxLines: 1,
                        style: a.type.title2.copyWith(color: c.onCover),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class CourseRow extends StatelessWidget {
  const CourseRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cover,
    this.segments,
    this.status,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget cover;
  final List<ProgressSegment>? segments;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              cover,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: a.type.headline.copyWith(color: c.ink)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                    if (segments != null) ...[
                      const SizedBox(height: 10),
                      SegmentedProgress(segments: segments!),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        status!,
                        style: a.type.caption.copyWith(color: c.inkSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Academy picker row: logo tile in the academy's own colour, name, host.
class AcademyRow extends StatelessWidget {
  const AcademyRow({
    super.key,
    required this.name,
    required this.host,
    required this.color,
    this.logo,
    this.onTap,
  });

  final String name;
  final String host;
  final Color color;
  final ImageProvider? logo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return MergeSemantics(
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: c.raised,
          child: Row(
            children: [
              AcademyLogo(academyName: name, image: logo, background: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: a.type.headline.copyWith(color: c.ink)),
                    Text(
                      host,
                      textDirection: TextDirection.ltr,
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              const ForwardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset grouped list (iOS settings shape; reads as a card-less list on
/// Android too). Hairlines between rows, radius 14.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.footer});

  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
          child: ColoredBox(
            color: c.raised,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 48),
                      child: Divider(height: 1, thickness: 1, color: c.rule),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: a.type.footnote.copyWith(color: c.inkSecondary),
            ),
          ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.icon,
    this.value,
    this.destructive = false,
    this.showChevron = true,
    this.onTap,
    this.valueLtr = false,
  });

  final String title;
  final IconData? icon;
  final String? value;
  final bool destructive;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool valueLtr;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final fg = destructive ? c.danger : c.ink;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AtlasSize.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: destructive ? c.danger : c.inkSecondary,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: value == null
                        ? Text(title, style: a.type.body.copyWith(color: fg))
                        : _TitleAndValue(
                            title: Text(
                              title,
                              style: a.type.body.copyWith(color: fg),
                            ),
                            value: Text(
                              value!,
                              textDirection: valueLtr
                                  ? TextDirection.ltr
                                  : null,
                              style: a.type.body.copyWith(
                                color: c.inkSecondary,
                              ),
                            ),
                          ),
                  ),
                  if (showChevron && !destructive && onTap != null) ...[
                    const SizedBox(width: 8),
                    const ForwardChevron(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title and value on one line, the value at the end; when both don't fit
/// on one line, the value goes under the title instead of wrapping (a phone
/// number or an address is never broken in the middle).
class _TitleAndValue extends StatelessWidget {
  const _TitleAndValue({required this.title, required this.value});
  final Text title;
  final Text value;

  double _width(BuildContext context, Text t) {
    final painter = TextPainter(
      text: TextSpan(text: t.data, style: t.style),
      textDirection: t.textDirection ?? Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final fits =
          _width(context, title) + gap + _width(context, value) <=
          constraints.maxWidth;
      if (fits) {
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: gap),
            value,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 2), value],
      );
    },
  );
}
