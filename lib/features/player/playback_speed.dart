import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// The speeds a lesson video can play at. Up to 2×: the server credits
/// watching at up to 2.5× real time, so a lesson that must be watched
/// still counts in full.
const playbackSpeeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// The learner's speed, kept for the next lesson and the next launch.
class PlaybackSpeedController extends Notifier<double> {
  static const _key = 'player.speed';

  @override
  double build() {
    final saved = ref.watch(sharedPreferencesProvider).getDouble(_key);
    return playbackSpeeds.contains(saved) ? saved! : 1.0;
  }

  Future<void> set(double speed) async {
    if (!playbackSpeeds.contains(speed)) return;
    state = speed;
    await ref.read(sharedPreferencesProvider).setDouble(_key, speed);
  }
}

final playbackSpeedProvider = NotifierProvider<PlaybackSpeedController, double>(
  PlaybackSpeedController.new,
);

/// 1.25 → "١٫٢٥×" in Arabic, "1.25×" in English; 1 → "١×".
String speedLabel(BuildContext context, double speed) {
  final s = speed == speed.roundToDouble()
      ? speed.toStringAsFixed(0)
      : speed.toString();
  final text = context.languageCode == 'ar'
      ? context.digits(s).replaceAll('.', '٫')
      : s;
  return '$text×';
}

/// Under a lesson video: the current speed, and a tap to change it.
class SpeedButton extends ConsumerWidget {
  const SpeedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final speed = ref.watch(playbackSpeedProvider);
    return Semantics(
      button: true,
      label: '${l.playerSpeedTitle}${context.sep}${speedLabel(context, speed)}',
      child: ExcludeSemantics(
        child: Pressable(
          onTap: () => _choose(context, ref),
          // 36pt to the eye, 48pt to the finger.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: speed == 1 ? c.sunken : c.tonal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.gauge,
                    size: 16,
                    color: speed == 1 ? c.inkSecondary : c.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l.playerSpeed} ${speedLabel(context, speed)}',
                    style: a.type.footnote.copyWith(
                      color: speed == 1 ? c.inkSecondary : c.accent,
                      fontWeight: FontWeight.w600,
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

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = ref.read(playbackSpeedProvider);
    final picked = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final a = context.atlas;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l.playerSpeedTitle,
                  style: a.type.title3.copyWith(color: a.colors.ink),
                ),
              ),
              for (final s in playbackSpeeds)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    s == 1
                        ? '${speedLabel(context, s)}${context.sep}${l.playerSpeedNormal}'
                        : speedLabel(context, s),
                    style: a.type.body.copyWith(color: a.colors.ink),
                  ),
                  trailing: s == current
                      ? Icon(LucideIcons.check, color: a.colors.accent)
                      : null,
                  selected: s == current,
                  onTap: () => Navigator.pop(context, s),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != current) {
      HapticFeedback.selectionClick();
      await ref.read(playbackSpeedProvider.notifier).set(picked);
    }
  }
}
