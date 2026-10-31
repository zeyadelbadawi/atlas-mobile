import 'dart:async';

import 'package:atlas_mobile/core/platform/screen_protection.dart';
import 'package:atlas_mobile/features/player/hosted_lesson_player.dart';
import 'package:atlas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../app/fake_video.dart';

class _NoProtection extends ScreenProtection {
  @override
  Future<bool> setSecure(bool on) async => false;

  @override
  Future<bool> isCaptured() async => false;

  @override
  Stream<CaptureEvent> get captureChanges => const Stream.empty();
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SizedBox(width: 400, child: child)),
);

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late FakeVideo video;
  setUp(() {
    video = FakeVideo();
    VideoPlayerPlatform.instance = video;
  });

  HostedLessonPlayer player({
    VoidCallback? onEnded,
    int start = 0,
    double speed = 1,
  }) => HostedLessonPlayer(
    url: 'https://videos.example.test/v.m3u8',
    hls: true,
    academyOrigin: 'https://ziadd.atlass.dpdns.org',
    watermarkCode: '6SG7A-QKN29',
    watermarkSecondary: 'g•••@example.test',
    startSeconds: start,
    protection: _NoProtection(),
    onEnded: onEnded,
    speed: speed,
  );

  testWidgets('plays at the chosen speed, and follows a change', (t) async {
    await t.pumpWidget(_host(player(speed: 1.5)));
    await _settle(t);
    // video_player hands the speed to the platform once it plays.
    await t.tap(find.byTooltip('تشغيل'));
    await _settle(t);
    expect(video.calls, contains('speed 1.5'));
    await t.pumpWidget(_host(player(speed: 2)));
    await _settle(t);
    expect(video.calls, contains('speed 2.0'));
  });

  testWidgets('plays from the academy origin, resumes, shows the watermark', (
    t,
  ) async {
    await t.pumpWidget(_host(player(start: 25)));
    await _settle(t);
    final s = video.source!;
    expect(s.uri, 'https://videos.example.test/v.m3u8');
    expect(s.formatHint, VideoFormat.hls);
    expect(s.httpHeaders['Origin'], 'https://ziadd.atlass.dpdns.org');
    expect(video.calls, contains('seek 25'));
    expect(find.textContaining('6SG7A-QKN29'), findsOneWidget);

    await t.tap(find.byTooltip('تشغيل'));
    await t.pump();
    expect(video.calls, contains('play'));
  });

  testWidgets('the end of the video calls onEnded once', (t) async {
    var ended = 0;
    await t.pumpWidget(_host(player(onEnded: () => ended++)));
    await _settle(t);
    video.events.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
    await t.pump();
    video.position = const Duration(seconds: 60);
    video.events.add(VideoEvent(eventType: VideoEventType.completed));
    await t.pump(const Duration(milliseconds: 600));
    expect(ended, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a video that cannot load says so', (t) async {
    video.failInit = true;
    await t.pumpWidget(_host(player()));
    await _settle(t);
    expect(find.text('This video could not be played.'), findsOneWidget);
  });
}
