import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The academy's device limit and the devices using it. Removing one frees
/// its slot (it signs nothing out; it just has to register again).
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    LearnerDevice d,
  ) async {
    final l = context.l10n;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: Text(l.devicesRemoveConfirm(context.deviceLabel(d.label))),
        actions: [
          ios
              ? CupertinoDialogAction(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l.commonCancel),
                )
              : TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l.commonCancel),
                ),
          ios
              ? CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(l.devicesRemove),
                )
              : TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(l.devicesRemove),
                ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(learningRepositoryProvider).removeDevice(d.id);
      ref.invalidate(devicesProvider);
    } on AtlasApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(ref, context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final devices = ref.watch(devicesProvider);
    return FormScreen(
      title: l.devicesTitle,
      icon: LucideIcons.smartphone,
      children: [
        AsyncBody<LearnerDevices>(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.devicesBody(context.digits('${d.maxDevices}')),
                style: a.type.body.copyWith(color: a.colors.inkSecondary),
              ),
              const SizedBox(height: AtlasSpace.s20),
              SettingsGroup(
                children: [
                  for (final device in d.devices)
                    _DeviceRow(
                      device: device,
                      onRemove: device.current
                          ? null
                          : () => _remove(context, ref, device),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, this.onRemove});
  final LearnerDevice device;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final label = device.label.toLowerCase();
    final icon =
        label.contains('ios') ||
            label.contains('android') ||
            label.contains('app')
        ? LucideIcons.smartphone
        : LucideIcons.monitor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconTile(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.label,
                  style: a.type.body.copyWith(color: a.colors.ink),
                ),
                Text(
                  device.current
                      ? l.devicesThis
                      : device.lastSeenAt == null
                      ? ''
                      : l.devicesLastSeen(
                          relative(context, device.lastSeenAt!),
                        ),
                  style: a.type.footnote.copyWith(
                    color: device.current
                        ? a.colors.accent
                        : a.colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: a.colors.danger),
              child: Text(l.devicesRemove),
            ),
        ],
      ),
    );
  }
}
