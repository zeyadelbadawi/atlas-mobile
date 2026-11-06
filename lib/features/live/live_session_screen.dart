import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/clock.dart';
import '../../core/learning/learning_models.dart';
import '../../core/platform/calendar.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// Joining opens this long before the start (the website's own window).
const liveJoinWindow = Duration(minutes: 15);

/// One live class: when it is, a countdown, and where to join it. Joining
/// itself happens on the academy's website (Zoom in the app comes later).
class LiveSessionScreen extends ConsumerWidget {
  const LiveSessionScreen({
    super.key,
    required this.courseId,
    required this.sessionId,
  });

  final String courseId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final value = ref.watch(liveSessionsProvider(courseId));
    return Scaffold(
      appBar: AppBar(),
      body: AsyncBody<List<LiveSession>>(
        value: value,
        onRetry: () => ref.invalidate(liveSessionsProvider(courseId)),
        data: (all) {
          final s = all.where((x) => x.id == sessionId).firstOrNull;
          if (s == null) {
            return Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: AtlasBanner(message: l.liveNotFound),
            );
          }
          return _Body(session: s, courseId: courseId);
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.session, required this.courseId});
  final LiveSession session;
  final String courseId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The countdown and the join button follow the clock.
    _tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _openOnWebsite() {
    final host = ref.read(sessionProvider).academy!.host;
    unawaited(
      launchUrl(
        Uri.https(
          host,
          '/my/courses/${widget.courseId}/activities/${widget.session.id}',
        ),
        mode: LaunchMode.inAppBrowserView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final s = widget.session;
    final now = clockNow();
    final lang = context.languageCode;
    final live =
        !s.cancelled &&
        (s.status == 'live' ||
            (!now.isBefore(s.startsAt.subtract(liveJoinWindow)) &&
                now.isBefore(s.endsAt)));
    final ended =
        !s.cancelled &&
        !live &&
        (s.status == 'ended' || !now.isBefore(s.endsAt));
    final upcoming = !s.cancelled && !live && !ended;
    final time = DateFormat.jm(lang);
    final date = DateFormat.yMMMMEEEEd(lang);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        AtlasSpace.s8,
        AtlasSpace.gutter,
        AtlasSpace.s32,
      ),
      children: [
        ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.video, size: 18, color: c.inkSecondary),
                  const SizedBox(width: 6),
                  Text(
                    l.unitLive,
                    style: a.type.footnote.copyWith(color: c.inkSecondary),
                  ),
                  if (live) ...[
                    const SizedBox(width: 10),
                    _LivePill(label: l.liveNow),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: SafeText(
                  s.title,
                  textDirection: contentDirection(context, s.title),
                  style: a.type.title1.copyWith(color: c.ink),
                ),
              ),
              if (s.hostName != null && s.hostName!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l.liveHost(s.hostName!.trim()),
                  style: a.type.subhead.copyWith(color: c.inkSecondary),
                ),
              ],
              const SizedBox(height: AtlasSpace.s20),
              AtlasCard(
                key: const ValueKey('live-when'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 18, color: c.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.digits(date.format(s.startsAt)),
                            style: a.type.headline.copyWith(color: c.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 18, color: c.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.digits(
                              l.liveTime(
                                time.format(s.startsAt),
                                time.format(s.endsAt),
                              ),
                            ),
                            style: a.type.body.copyWith(color: c.ink),
                          ),
                        ),
                      ],
                    ),
                    if (upcoming) ...[
                      const SizedBox(height: AtlasSpace.s16),
                      _Countdown(until: s.startsAt, now: now),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AtlasSpace.s16),
              if (s.cancelled)
                AtlasBanner(
                  kind: AtlasBannerKind.error,
                  message: l.liveCancelled,
                )
              else if (ended) ...[
                AtlasBanner(message: l.liveEnded),
                if (s.recordingAvailable) ...[
                  const SizedBox(height: AtlasSpace.s12),
                  AtlasButton(
                    label: l.liveRecording,
                    icon: LucideIcons.circlePlay,
                    style: AtlasButtonStyle.tonal,
                    onPressed: _openOnWebsite,
                  ),
                ],
              ] else if (live)
                AtlasButton(
                  key: const ValueKey('live-join'),
                  label: l.liveJoin,
                  icon: LucideIcons.video,
                  onPressed: _openOnWebsite,
                )
              else ...[
                Text(
                  l.liveJoinNote,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
                const SizedBox(height: AtlasSpace.s8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('live-calendar'),
                    icon: const Icon(LucideIcons.calendarPlus, size: 18),
                    label: Text(l.calendarAdd),
                    onPressed: () async {
                      final ok = await ref.read(addToCalendarProvider)((
                        title: s.title,
                        description: l.unitLive,
                        dueAt: s.endsAt,
                        startsAt: s.startsAt,
                      ));
                      ref.read(analyticsProvider).event('calendar_add', {
                        'ok': ok ? 1 : 0,
                        'kind': 'live',
                      });
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l.calendarFailed)),
                          );
                      }
                    },
                  ),
                ),
              ],
              if (s.description != null &&
                  s.description!.trim().isNotEmpty) ...[
                const SizedBox(height: AtlasSpace.s24),
                Text(
                  s.description!.trim(),
                  textDirection: contentDirection(context, s.description!),
                  style: a.type.body.copyWith(color: c.ink),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: a.type.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Days, hours and minutes to the start, each with its unit underneath.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.until, required this.now});
  final DateTime until;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final left = until.difference(now);
    final parts = [
      (left.inDays, l.liveDays),
      (left.inHours % 24, l.liveHours),
      (left.inMinutes % 60, l.liveMinutes),
    ];
    return Semantics(
      label: l.liveStartsIn,
      child: Row(
        key: const ValueKey('live-countdown'),
        children: [
          for (final (n, unit) in parts) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: c.tonal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      context.digits('$n'),
                      style: a.type.title2.copyWith(color: c.accent),
                    ),
                    Text(
                      unit,
                      style: a.type.caption.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (unit != l.liveMinutes) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
