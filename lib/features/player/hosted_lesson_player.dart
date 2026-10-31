import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../app/ui_helpers.dart';
import '../../core/platform/screen_protection.dart';
import 'playback_session.dart';
import 'watermark_overlay.dart';

/// A video uploaded to Atlas (MP4 or an HLS stream), played natively: the
/// watermark on top, the playback lease running while it plays, capture
/// protection, and resume from where the learner left off. The same rules
/// as [YouTubeLessonPlayer], without a web page.
class HostedLessonPlayer extends StatefulWidget {
  const HostedLessonPlayer({
    super.key,
    required this.url,
    required this.academyOrigin,
    required this.watermarkCode,
    this.hls = false,
    this.posterUrl,
    this.watermarkSecondary,
    this.session,
    this.startSeconds = 0,
    this.protection,
    this.onEnded,
    this.controller,
    this.speed = 1,
    this.recordingMessage = 'Stop screen recording to keep watching.',
    this.failedMessage = 'This video could not be played.',
  });

  final String url;
  final bool hls;
  final String? posterUrl;

  /// The academy's origin. Sent as Origin / Referer: the video host only
  /// serves the academy's own sites.
  final String academyOrigin;
  final String watermarkCode;
  final String? watermarkSecondary;
  final PlaybackSession? session;
  final int startSeconds;
  final ScreenProtection? protection;
  final VoidCallback? onEnded;

  /// Tests pass their own controller.
  final VideoPlayerController? controller;

  /// Playback speed (1 = normal).
  final double speed;
  final String recordingMessage;
  final String failedMessage;

  @override
  State<HostedLessonPlayer> createState() => _HostedLessonPlayerState();
}

class _HostedLessonPlayerState extends State<HostedLessonPlayer>
    with WidgetsBindingObserver {
  late final VideoPlayerController _video =
      widget.controller ??
      VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        formatHint: widget.hls ? VideoFormat.hls : null,
        httpHeaders: {
          'Origin': widget.academyOrigin,
          'Referer': '${widget.academyOrigin}/',
        },
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
  late final ScreenProtection _protection =
      widget.protection ?? ScreenProtection();
  StreamSubscription<CaptureEvent>? _capture;
  Timer? _hide;
  bool _captured = false, _ready = false, _failed = false;
  bool _wasPlaying = false, _ended = false, _controls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_protection.setSecure(true));
    unawaited(_protection.isCaptured().then(_setCaptured));
    _capture = _protection.captureChanges.listen((event) {
      if (event.isScreenshot) {
        _pause();
      } else {
        _setCaptured(event.isCaptured);
      }
    });
    _video.addListener(_onTick);
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _video.initialize();
      if (widget.startSeconds > 0) {
        await _video.seekTo(Duration(seconds: widget.startSeconds));
      }
      if (widget.speed != 1) await _video.setPlaybackSpeed(widget.speed);
      if (mounted) setState(() => _ready = true);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(HostedLessonPlayer old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed && _ready) {
      unawaited(_video.setPlaybackSpeed(widget.speed).catchError((_) {}));
    }
  }

  void _onTick() {
    final v = _video.value;
    if (v.hasError && !_failed) {
      setState(() => _failed = true);
      return;
    }
    widget.session?.positionSeconds = v.position.inMilliseconds / 1000;
    if (v.isPlaying != _wasPlaying) {
      _wasPlaying = v.isPlaying;
      v.isPlaying ? widget.session?.start() : widget.session?.pause();
      if (!v.isPlaying) _showControls(autoHide: false);
    }
    final done =
        v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 300);
    if (done && !_ended) {
      _ended = true;
      widget.session?.pause();
      widget.onEnded?.call();
    } else if (!done) {
      _ended = false;
    }
    if (mounted) setState(() {});
  }

  void _setCaptured(bool value) {
    if (!mounted || value == _captured) return;
    setState(() => _captured = value);
    if (value) _pause();
  }

  void _pause() {
    unawaited(_video.pause());
    widget.session?.pause();
  }

  void _toggle() {
    if (!_ready || _captured) return;
    if (_video.value.isPlaying) {
      _pause();
    } else {
      if (_ended) unawaited(_video.seekTo(Duration.zero));
      unawaited(_video.play());
      _showControls();
    }
  }

  void _skip(int seconds) {
    final v = _video.value;
    var to = v.position + Duration(seconds: seconds);
    if (to < Duration.zero) to = Duration.zero;
    if (to > v.duration) to = v.duration;
    unawaited(_video.seekTo(to));
    _showControls();
  }

  void _showControls({bool autoHide = true}) {
    _hide?.cancel();
    if (!_controls) setState(() => _controls = true);
    if (autoHide && _video.value.isPlaying) {
      _hide = Timer(const Duration(seconds: 3), () {
        if (mounted && _video.value.isPlaying) {
          setState(() => _controls = false);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hide?.cancel();
    _video.removeListener(_onTick);
    unawaited(_video.dispose());
    unawaited(_capture?.cancel());
    unawaited(_protection.setSecure(false));
    unawaited(widget.session?.release());
    super.dispose();
  }

  static String _time(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final v = _video.value;
    final ratio = _ready && v.aspectRatio > 0 ? v.aspectRatio : 16 / 9;
    final poster = widget.posterUrl;
    return AspectRatio(
      aspectRatio: ratio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (_ready)
              VideoPlayer(_video)
            else if (poster != null)
              Image.network(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            // Taps anywhere show the controls; the buttons sit above.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controls && v.isPlaying
                  ? setState(() => _controls = false)
                  : _showControls(),
            ),
            if (!_ready && !_failed)
              const Center(child: CircularProgressIndicator()),
            if (_ready)
              AnimatedOpacity(
                opacity: _controls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controls,
                  child: _Controls(
                    playing: v.isPlaying,
                    buffering: v.isBuffering,
                    position: _time(v.position),
                    duration: _time(v.duration),
                    progress: _VideoBar(controller: _video),
                    onToggle: _toggle,
                    onBack: () => _skip(-10),
                    onForward: () => _skip(10),
                  ),
                ),
              ),
            WatermarkOverlay(
              code: widget.watermarkCode,
              secondary: widget.watermarkSecondary,
            ),
            if (_captured)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: ColoredBox(
                  color: const Color(0xCC000000),
                  child: _Message(widget.recordingMessage),
                ),
              ),
            if (_failed)
              ColoredBox(
                color: Colors.black,
                child: _Message(widget.failedMessage),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

/// Back 10 s, play / pause, forward 10 s in the middle; the time and the
/// scrubber along the bottom. Player controls stay left-to-right in every
/// language, like the timeline they control.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.buffering,
    required this.position,
    required this.duration,
    required this.progress,
    required this.onToggle,
    required this.onBack,
    required this.onForward,
  });

  final bool playing, buffering;
  final String position, duration;
  final Widget progress;
  final VoidCallback onToggle, onBack, onForward;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const time = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33000000), Color(0x22000000), Color(0x99000000)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundButton(
                    icon: LucideIcons.rotateCcw,
                    tooltip: l.playerBack10,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 24),
                  buffering && playing
                      ? const SizedBox.square(
                          dimension: 56,
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : _RoundButton(
                          icon: playing ? LucideIcons.pause : LucideIcons.play,
                          tooltip: playing ? l.playerPause : l.playerPlay,
                          size: 56,
                          onTap: onToggle,
                        ),
                  const SizedBox(width: 24),
                  _RoundButton(
                    icon: LucideIcons.rotateCw,
                    tooltip: l.playerForward10,
                    onTap: onForward,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 6,
              child: Row(
                children: [
                  Text(position, style: time),
                  const SizedBox(width: 10),
                  Expanded(child: progress),
                  const SizedBox(width: 10),
                  Text(duration, style: time),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x66000000),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      iconSize: size * 0.45,
      constraints: BoxConstraints.tight(Size.square(size)),
      color: Colors.white,
      icon: Icon(icon),
      onPressed: onTap,
    ),
  );
}

class _VideoBar extends StatelessWidget {
  const _VideoBar({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 24,
    child: Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          colors: const VideoProgressColors(
            playedColor: Color(0xFFE0A424),
            bufferedColor: Color(0x66FFFFFF),
            backgroundColor: Color(0x33FFFFFF),
          ),
        ),
      ),
    ),
  );
}
