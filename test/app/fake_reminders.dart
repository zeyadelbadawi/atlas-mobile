import 'package:atlas_mobile/core/reminders/local_reminders.dart';

/// Records what the app scheduled instead of asking the phone.
class FakeReminders implements LocalReminders {
  FakeReminders({this.granted = true});

  /// What the system answers when asked for permission.
  bool granted;
  final scheduled =
      <({int id, DateTime? when, String title, String body, String path})>[];
  ({int hour, int minute})? dailyAt;
  int asked = 0;
  int cancels = 0;

  @override
  Future<void> init(void Function(String path) onOpen) async {}

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted;
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
    dailyAt = (hour: hour, minute: minute);
    scheduled.add((id: id, when: null, title: title, body: body, path: path));
  }

  @override
  Future<void> at({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String path,
  }) async =>
      scheduled.add((id: id, when: when, title: title, body: body, path: path));

  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled.clear();
    dailyAt = null;
  }
}
