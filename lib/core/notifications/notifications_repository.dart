import '../api/atlas_api_client.dart';

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      type = j['type'] as String? ?? 'system',
      priority = j['priority'] as String? ?? 'low',
      titleKey = j['titleKey'] as String? ?? '',
      messageKey = j['messageKey'] as String? ?? '',
      values = j['values'] is Map
          ? Map<String, dynamic>.from(j['values'] as Map)
          : const {},
      isRead = j['isRead'] == true,
      actionUrl = j['actionUrl'] as String?,
      createdAt = _date(j['createdAt']) ?? DateTime.now();

  final String id;

  /// system | account | billing | security | activity | announcement
  final String type;
  final String priority;
  final String titleKey;
  final String messageKey;
  final Map<String, dynamic> values;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  AppNotification read() => AppNotification.fromJson({
    'id': id,
    'type': type,
    'priority': priority,
    'titleKey': titleKey,
    'messageKey': messageKey,
    'values': values,
    'isRead': true,
    'actionUrl': actionUrl,
    'createdAt': createdAt.toUtc().toIso8601String(),
  });
}

class NotificationPage {
  NotificationPage({required this.items, required this.hasMore});
  final List<AppNotification> items;
  final bool hasMore;
}

class Announcement {
  Announcement.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      audience = j['audience'] as String? ?? 'academy',
      courseId = j['courseId'] as String?,
      authorName = j['authorName'] as String? ?? '',
      title = j['title'] as String? ?? '',
      body = j['body'] as String? ?? '',
      publishedAt = _date(j['publishedAt']) ?? _date(j['createdAt']);

  final String id;
  final String audience;
  final String? courseId;
  final String authorName;
  final String title;
  final String body;
  final DateTime? publishedAt;
}

/// The learner's notification feed, announcements and push devices.
class NotificationsRepository {
  NotificationsRepository(this.client);

  final AtlasApiClient client;

  static const pageSize = 30;

  Future<NotificationPage> list({int page = 1}) async {
    final body = await client.get<Map<String, dynamic>>(
      'notifications',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = (body['items'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => AppNotification.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final p = body['pagination'];
    final totalPages = p is Map ? (p['totalPages'] as num?)?.toInt() ?? 1 : 1;
    return NotificationPage(items: items, hasMore: page < totalPages);
  }

  Future<int> unreadCount() async {
    final body = await client.get<Map<String, dynamic>>(
      'notifications/summary',
    );
    return (body['unread'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) =>
      client.patch<dynamic>('notifications/$id/read');

  Future<void> markAllRead() =>
      client.post<dynamic>('notifications/read-all', data: const {});

  Future<List<Announcement>> announcements() async {
    final body = await client.get<Map<String, dynamic>>(
      'announcements',
      query: {'pageSize': 50},
    );
    return (body['items'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => Announcement.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Announcement> announcement(String id) async => Announcement.fromJson(
    await client.get<Map<String, dynamic>>('announcements/$id'),
  );

  /// Registers this phone for push on the current academy session. Returns
  /// the device id (to remove it on sign-out).
  Future<String?> registerPushDevice({
    required String token,
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    final body = await client.put<Map<String, dynamic>>(
      'users/me/push-devices',
      data: {
        'token': token,
        'platform': platform,
        'appVersion': appVersion,
        'locale': locale,
      },
    );
    return body['id'] as String?;
  }

  Future<void> removePushDevice(String id) =>
      client.delete<dynamic>('users/me/push-devices/$id');
}
