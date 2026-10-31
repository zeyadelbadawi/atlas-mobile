import 'dart:async';

import 'package:atlas_mobile/core/platform/screen_protection.dart';
import 'package:atlas_mobile/features/player/hosted_lesson_player.dart';
import 'package:atlas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A video platform that "plays" a 60-second clip, so the player's own
/// logic (resume, play / pause, the end of the video) can be tested
/// without a device.
class _FakeVideo extends VideoPlayerPlatform {
  // Single-subscription: it holds the first event until the player listens.
  final events = StreamController<VideoEvent>();
  final calls = <String>[];
  DataSource? source;
  Duration position = Duration.zero;
  bool failInit = false;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    source = options.dataSource;
    scheduleMicrotask(() {
      if (failInit) {
        events.addError(
          PlatformException(code: 'boom', message: 'cannot open'),
        );
      } else {
        events.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 60),
            size: const Size(1280, 720),
          ),
        );
      }
    });
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration to) async {
    calls.add('seek ${to.inSeconds}');
    position = to;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setAllowBackgroundPlayback(bool allow) async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black);
}

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
  late _FakeVideo video;
  setUp(() {
    video = _FakeVideo();
    VideoPlayerPlatform.instance = video;
  });

  HostedLessonPlayer player({VoidCallback? onEnded, int start = 0}) =>
      HostedLessonPlayer(
        url: 'https://videos.example.test/v.m3u8',
        hls: true,
        academyOrigin: 'https://ziadd.atlass.dpdns.org',
        watermarkCode: '6SG7A-QKN29',
        watermarkSecondary: 'g•••@example.test',
        startSeconds: start,
        protection: _NoProtection(),
        onEnded: onEnded,
      );

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
