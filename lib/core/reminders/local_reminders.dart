import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notifications the phone shows on its own, at a set time, with no server:
/// the daily study reminder and the due-date reminders. Behind an
/// interface so tests can see what was scheduled.
abstract class LocalReminders {
  /// [onOpen] gets the app path a tapped reminder carries.
  Future<void> init(void Function(String path) onOpen);

  /// Asks the system (Android 13+, iOS). True when reminders may show.
  Future<bool> requestPermission();

  /// Every day at [hour]:[minute] local time.
  Future<void> daily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String path,
  });

  /// Once, at [when].
  Future<void> at({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String path,
  });

  Future<void> cancelAll();
}

class PluginReminders implements LocalReminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Study and due-date reminders',
    icon: 'ic_notification',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init(void Function(String path) onOpen) =>
      _ready ??= _init(onOpen);

  Future<void> _init(void Function(String path) onOpen) async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e) {
      // UTC: reminders still come, an hour off across a clock change.
      debugPrint('reminders time zone: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Asked when the learner turns a reminder on, never at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final path? when path.isNotEmpty) onOpen(path);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final path = launch!.notificationResponse?.payload;
      if (path != null && path.isNotEmpty) onOpen(path);
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> daily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String path,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: first,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: path,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> at({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String path,
  }) => _plugin.zonedSchedule(
    id: id,
    scheduledDate: tz.TZDateTime.from(when, tz.local),
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: title,
    body: body,
    payload: path,
  );

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
