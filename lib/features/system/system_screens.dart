import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// Shown instead of the app when this version is below the minimum
/// (`/public/mobile/config`), or while Atlas is in maintenance.
class SystemGateScreen extends StatelessWidget {
  const SystemGateScreen.update({super.key, required this.storeUrl})
    : maintenance = false;
  const SystemGateScreen.maintenance({super.key})
    : maintenance = true,
      storeUrl = null;

  final bool maintenance;
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpace.gutter),
          child: ReadableWidth(
            form: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  maintenance ? LucideIcons.clock : LucideIcons.smartphone,
                  size: 40,
                  color: a.colors.accent,
                ),
                const SizedBox(height: AtlasSpace.s20),
                Text(
                  maintenance ? l.maintenanceTitle : l.updateTitle,
                  style: a.type.title1.copyWith(color: a.colors.ink),
                ),
                const SizedBox(height: AtlasSpace.s12),
                Text(
                  maintenance ? l.maintenanceBody : l.updateBody,
                  style: a.type.body.copyWith(color: a.colors.inkSecondary),
                ),
                const Spacer(),
                if (!maintenance && storeUrl != null)
                  AtlasButton(
                    label: l.updateButton,
                    onPressed: () => launchUrl(
                      Uri.parse(storeUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
