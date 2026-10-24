import 'dart:async';

import '../../core/api/api_error.dart';
import '../../core/api/atlas_api_client.dart';

/// The server side of watching one lesson: the playback lease and its
/// heartbeat (`playbackLease` in the lesson grant), the release when the
/// learner leaves, and the tamper report.
///
/// The backend allows a limited number of concurrent learning sessions; the
/// lease is how it knows this phone is still watching. A missed heartbeat
/// lets the lease lapse after `ttlSeconds`; a release frees it at once.
class PlaybackSession {
  PlaybackSession({
    required this.client,
    required this.courseId,
    required this.lessonId,
    required this.leaseId,
    required this.heartbeatInterval,
    this.onLeaseLost,
    this.onHeartbeat,
  });

  /// Each heartbeat's answer (`completionEligible`, `maxWatchedRatio`, …).
  void Function(Map<String, dynamic>)? onHeartbeat;

  /// Builds a session from the `playbackLease` object of a lesson grant.
  /// Returns null when the grant came without a lease (lease store down).
  static PlaybackSession? fromGrant(
    AtlasApiClient client,
    Map<String, dynamic> grant, {
    void Function(AtlasApiException)? onLeaseLost,
  }) {
    final lease = grant['playbackLease'];
    if (lease is! Map) return null;
    return PlaybackSession(
      client: client,
      courseId: grant['courseId'] as String,
      lessonId: grant['lessonId'] as String,
      leaseId: lease['leaseId'] as String,
      heartbeatInterval: Duration(
        seconds: (lease['heartbeatSeconds'] as num?)?.toInt() ?? 20,
      ),
      onLeaseLost: onLeaseLost,
    );
  }

  final AtlasApiClient client;
  final String courseId;
  final String lessonId;
  final String leaseId;
  final Duration heartbeatInterval;

  /// Another device took over, or the enrolment ended: stop the video.
  final void Function(AtlasApiException)? onLeaseLost;

  Timer? _timer;
  int _position = 0;
  bool _released = false;

  /// Latest playhead, reported by the player.
  set positionSeconds(num value) => _position = value.floor().clamp(0, 86400);

  bool get isRunning => _timer != null;

  void start() {
    if (_released) return;
    _timer ??= Timer.periodic(heartbeatInterval, (_) => beat());
    unawaited(beat());
  }

  /// Pauses heartbeats (app in background, video paused). The lease lapses
  /// on its own after its TTL; [release] frees it immediately.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  Future<Map<String, dynamic>?> beat() async {
    try {
      final body = await client.post<Map<String, dynamic>>(
        'learning/courses/$courseId/playback',
        data: {
          'lessonId': lessonId,
          'positionSeconds': _position,
          'leaseId': leaseId,
        },
      );
      onHeartbeat?.call(body);
      if (body['leaseHeld'] == false) {
        pause();
        onLeaseLost?.call(
          const AtlasApiException(
            kind: 'conflict',
            messageKey: 'errors.learning.leaseLost',
          ),
        );
      }
      return body;
    } on AtlasApiException catch (e) {
      if (e.status == 403 || e.status == 409) {
        pause();
        onLeaseLost?.call(e);
      }
      return null;
    }
  }

  Future<void> release() async {
    pause();
    if (_released) return;
    _released = true;
    try {
      await client.post<void>(
        'learning/courses/$courseId/playback/release',
        data: {'leaseId': leaseId},
      );
    } on AtlasApiException {
      // The lease expires on its own.
    }
  }

  /// One report per 30 s at most; the server throttles as well.
  DateTime? _lastTamperReport;
  Future<void> reportTamper(String code) async {
    final now = DateTime.now();
    if (_lastTamperReport != null &&
        now.difference(_lastTamperReport!) < const Duration(seconds: 30)) {
      return;
    }
    _lastTamperReport = now;
    try {
      await client.post<void>(
        'learning/watermarks/tamper',
        data: {'code': code},
      );
    } on AtlasApiException {
      // Best effort, like the website.
    }
  }
}
