import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// `85٪` in Arabic, `85%` in English.
String percentText(BuildContext context, double value) =>
    context.l10n.quizPercent(context.digits('${value.round()}'));

/// A trimmed number: `2`, `2.5`.
String numberText(BuildContext context, double value) => context.digits(
  value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1),
);

/// Label / value facts, one per line, on a card with hairlines between.
/// The values are what the learner decides on, so they are set in ink,
/// labels in grey.
class FactList extends StatelessWidget {
  const FactList({super.key, required this.facts});
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return AtlasCard(
      padding: const EdgeInsets.symmetric(horizontal: AtlasSpace.s16),
      child: Column(
        children: [
          for (final (i, (label, value)) in facts.indexed)
            MergeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: i == facts.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: c.rule)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        label,
                        style: a.type.subhead.copyWith(color: c.inkSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 3,
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: a.type.headline.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The top of a quiz or assignment: a tinted icon tile, what it is
/// (quiz, assignment) and its title.
class AssessmentHeader extends StatelessWidget {
  const AssessmentHeader({
    super.key,
    required this.icon,
    required this.kind,
    required this.title,
  });
  final IconData icon;
  final String kind;
  final String title;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.tonal,
                    borderRadius: BorderRadius.circular(AtlasRadius.md),
                  ),
                  child: Icon(icon, size: 22, color: c.accent),
                ),
              ),
              const SizedBox(width: 12),
              Text(kind, style: a.type.subhead.copyWith(color: c.accent)),
            ],
          ),
        ),
        const SizedBox(height: AtlasSpace.s12),
        Entrance(
          order: 1,
          child: Semantics(
            header: true,
            child: Text(
              title,
              textDirection: contentDirection(context, title),
              style: a.type.title1.copyWith(color: c.ink),
            ),
          ),
        ),
      ],
    );
  }
}

enum PillTone { neutral, success, danger, accent }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
  });
  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final fg = switch (tone) {
      PillTone.success => c.success,
      PillTone.danger => c.danger,
      PillTone.accent => c.accent,
      PillTone.neutral => c.inkSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: a.type.footnote.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A choice in a question. Radio for one answer, check box for several.
/// The whole row is the target (52 pt), selected rows carry the accent.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.multiple,
    this.onTap,
    this.verdict,
  });

  final String label;
  final bool selected;
  final bool multiple;
  final VoidCallback? onTap;

  /// Results only: true marks the correct choice, false a wrong pick.
  final bool? verdict;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final ring = verdict == true
        ? c.success
        : verdict == false
        ? c.danger
        : selected
        ? c.accent
        : c.rule;
    final icon = verdict == true
        ? LucideIcons.circleCheck
        : verdict == false
        ? LucideIcons.circleX
        : multiple
        ? (selected ? LucideIcons.squareCheck : LucideIcons.square)
        : (selected ? LucideIcons.circleDot : LucideIcons.circle);
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: !multiple,
      button: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: AnimatedContainer(
          duration: AtlasMotion.quick,
          curve: AtlasMotion.easeOut,
          constraints: const BoxConstraints(minHeight: AtlasSize.button),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected && verdict == null ? c.tonal : c.raised,
            borderRadius: BorderRadius.circular(AtlasRadius.lg),
            border: Border.all(
              color: ring,
              width: selected || verdict != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: verdict == true
                    ? c.success
                    : verdict == false
                    ? c.danger
                    : selected
                    ? c.accent
                    : c.inkTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: a.type.body.copyWith(color: c.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-line answer field (essays, short answers, assignment responses).
class AnswerField extends StatelessWidget {
  const AnswerField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helper,
    this.minLines = 1,
    this.maxLines = 4,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final int minLines, maxLines;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: a.type.footnote.copyWith(color: c.inkSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: a.type.body.copyWith(color: c.ink),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: a.type.body.copyWith(color: c.inkTertiary),
            filled: true,
            fillColor: c.sunken,
            counterStyle: a.type.caption.copyWith(color: c.inkTertiary),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.md),
              borderSide: BorderSide(color: c.accent, width: 2),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: a.type.footnote.copyWith(color: c.inkTertiary)),
        ],
      ],
    );
  }
}

/// A raised section with a title, for the intro and results.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.tonal = false});
  final Widget child;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    if (!tonal) {
      return AtlasCard(
        padding: const EdgeInsets.all(AtlasSpace.s16),
        child: child,
      );
    }
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.s16),
      decoration: BoxDecoration(
        color: c.tonal,
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
      child: child,
    );
  }
}
