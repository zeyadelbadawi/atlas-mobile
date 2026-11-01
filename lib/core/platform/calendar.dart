import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A due date (or, with [startsAt], a class) to put in the phone's calendar.
typedef DueEvent = ({
  String title,
  String description,
  DateTime dueAt,
  DateTime? startsAt,
});

/// Opens the calendar app's own "new event" screen, filled in, for the
/// learner to confirm. Android: no permission (the calendar app saves it).
/// iOS 17+: none either; older iOS asks once. False when it could not open.
typedef AddToCalendar = Future<bool> Function(DueEvent event);

final addToCalendarProvider = Provider<AddToCalendar>(
  (_) => (e) async {
    try {
      return await Add2Calendar.addEvent2Cal(
        Event(
          title: e.title,
          description: e.description,
          // A class from its start to its end; a deadline as an hour-long
          // slot ending at it.
          startDate: e.startsAt ?? e.dueAt.subtract(const Duration(hours: 1)),
          endDate: e.dueAt,
          iosParams: IOSParams(
            reminder: e.startsAt == null
                ? const Duration(hours: 1)
                : const Duration(minutes: 15),
          ),
        ),
      );
    } on Object {
      return false;
    }
  },
);
