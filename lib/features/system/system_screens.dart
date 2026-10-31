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
    final c = a.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpace.gutter),
          child: ReadableWidth(
            form: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Atlas's own moment: the app is Atlas here, not an academy.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AtlasLockup(
                    height: 22,
                    markColor: c.accent,
                    wordColor: c.ink,
                  ),
                ),
                const Spacer(),
                Entrance(
                  child: ExcludeSemantics(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.tonal,
                      ),
                      child: Icon(
                        maintenance ? LucideIcons.wrench : LucideIcons.download,
                        size: 40,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s24),
                Entrance(
                  order: 1,
                  child: Semantics(
                    header: true,
                    child: Text(
                      maintenance ? l.maintenanceTitle : l.updateTitle,
                      textAlign: TextAlign.center,
                      style: a.type.title1.copyWith(color: c.ink),
                    ),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s12),
                Entrance(
                  order: 2,
                  child: Text(
                    maintenance ? l.maintenanceBody : l.updateBody,
                    textAlign: TextAlign.center,
                    style: a.type.body.copyWith(color: c.inkSecondary),
                  ),
                ),
                const Spacer(flex: 2),
                if (!maintenance && storeUrl != null)
                  AtlasButton(
                    label: l.updateButton,
                    icon: LucideIcons.download,
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
