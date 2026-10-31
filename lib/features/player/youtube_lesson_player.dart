import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/platform/screen_protection.dart';
import 'playback_session.dart';
import 'watermark_overlay.dart';
import 'youtube_embed_html.dart';

/// A YouTube lesson: the embed in a WebView, the watermark on top, the
/// playback lease running while it plays, and capture protection.
///
/// Pauses (and releases nothing — the lease simply stops beating) when the
/// app goes to the background; [PlaybackSession.release] runs on dispose.
class YouTubeLessonPlayer extends StatefulWidget {
  const YouTubeLessonPlayer({
    super.key,
    required this.videoId,
    required this.academyOrigin,
    required this.watermarkCode,
    this.watermarkSecondary,
    this.session,
    this.startSeconds = 0,
    this.protection,
    this.onEnded,
    this.speed = 1,
    this.recordingMessage = 'Stop screen recording to keep watching.',
    this.failedMessage = 'This video could not be played.',
  });

  /// Shown over the picture while iOS records or mirrors the screen.
  final String recordingMessage;

  /// Shown when YouTube reports an error.
  final String failedMessage;

  final String videoId;

  /// `AcademyEndpoint.originHeader` — the WebView's base URL.
  final String academyOrigin;
  final String watermarkCode;
  final String? watermarkSecondary;
  final PlaybackSession? session;
  final int startSeconds;
  final ScreenProtection? protection;
  final VoidCallback? onEnded;

  /// Playback speed (1 = normal).
  final double speed;

  @override
  State<YouTubeLessonPlayer> createState() => _YouTubeLessonPlayerState();
}

class _YouTubeLessonPlayerState extends State<YouTubeLessonPlayer>
    with WidgetsBindingObserver {
  late final WebViewController _web;
  late final ScreenProtection _protection =
      widget.protection ?? ScreenProtection();
  StreamSubscription<CaptureEvent>? _capture;
  bool _captured = false;
  bool _ready = false;
  String? _errorKey;

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

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('Atlas', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final allowed =
                uri != null &&
                isAllowedPlayerNavigation(
                  uri,
                  academyOrigin: widget.academyOrigin,
                );
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(
        youtubeEmbedHtml(
          videoId: widget.videoId,
          origin: widget.academyOrigin,
          startSeconds: widget.startSeconds,
        ),
        baseUrl: widget.academyOrigin,
      );
  }

  void _setCaptured(bool value) {
    if (!mounted || value == _captured) return;
    setState(() => _captured = value);
    if (value) _pause();
  }

  void _onMessage(JavaScriptMessage message) {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(message.message) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    switch (m['t']) {
      case 'ready':
        setState(() => _ready = true);
        if (widget.speed != 1) _setSpeed(widget.speed);
      case 'time':
        final v = m['v'];
        if (v is num) widget.session?.positionSeconds = v;
      case 'state':
        // YT.PlayerState: 0 ended, 1 playing, 2 paused, 3 buffering.
        switch (m['s']) {
          case 1:
            widget.session?.start();
          case 2:
            widget.session?.pause();
          case 0:
            widget.session?.pause();
            widget.onEnded?.call();
        }
      case 'error':
        setState(() => _errorKey = 'learning.player.youtubeError');
    }
  }

  void _setSpeed(double speed) =>
      unawaited(_web.runJavaScript('atlasRate($speed)').catchError((_) {}));

  @override
  void didUpdateWidget(YouTubeLessonPlayer old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed && _ready) _setSpeed(widget.speed);
  }

  void _pause() {
    unawaited(_web.runJavaScript('atlasPause()').catchError((_) {}));
    widget.session?.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_capture?.cancel());
    unawaited(_protection.setSecure(false));
    unawaited(widget.session?.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _web),
            if (!_ready && _errorKey == null)
              const ColoredBox(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              ),
            WatermarkOverlay(
              code: widget.watermarkCode,
              secondary: widget.watermarkSecondary,
            ),
            if (_captured)
              // iOS is recording or mirroring: hide the picture, keep the
              // watermark-free message readable.
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: ColoredBox(
                  color: const Color(0xCC000000),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.recordingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            if (_errorKey != null)
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.failedMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
