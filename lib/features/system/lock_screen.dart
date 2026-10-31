import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_lock.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';

/// Covers the app while it is locked, and asks the phone at once.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _asked = false;

  Future<void> _unlock() async {
    _asked = true;
    await ref.read(appLockProvider.notifier).unlock(context.l10n.lockReason);
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final signedIn = ref.watch(
      sessionProvider.select((s) => s.status == SessionStatus.signedIn),
    );
    final covering = lock.locked && signedIn;
    if (!covering) {
      _asked = false;
    } else if (!_asked) {
      // Once per lock; after that the button asks again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_asked) _unlock();
      });
    }
    return Stack(
      children: [
        // Hidden from screen readers and taps while locked, not just covered.
        ExcludeSemantics(
          excluding: covering,
          child: IgnorePointer(ignoring: covering, child: widget.child),
        ),
        if (covering) _LockScreen(onUnlock: _unlock),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    return Material(
      key: const ValueKey('app-lock'),
      color: c.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpace.gutter),
          child: Column(
            children: [
              const Spacer(),
              Icon(LucideIcons.lockKeyhole, size: 56, color: c.accent),
              const SizedBox(height: AtlasSpace.s16),
              Text(
                l.lockTitle,
                textAlign: TextAlign.center,
                style: a.type.title2.copyWith(color: c.ink),
              ),
              const SizedBox(height: 6),
              Text(
                l.lockBody,
                textAlign: TextAlign.center,
                style: a.type.body.copyWith(color: c.inkSecondary),
              ),
              const Spacer(),
              ReadableWidth(
                form: true,
                child: AtlasButton(
                  label: l.lockUnlock,
                  icon: LucideIcons.fingerprint,
                  onPressed: onUnlock,
                ),
              ),
              const SizedBox(height: AtlasSpace.s16),
            ],
          ),
        ),
      ),
    );
  }
}
