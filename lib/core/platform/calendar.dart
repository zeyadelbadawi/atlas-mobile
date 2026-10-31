import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A due date to put in the phone's calendar.
typedef DueEvent = ({String title, String description, DateTime dueAt});

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
          // An hour-long slot ending at the deadline.
          startDate: e.dueAt.subtract(const Duration(hours: 1)),
          endDate: e.dueAt,
          iosParams: const IOSParams(reminder: Duration(hours: 1)),
        ),
      );
    } on Object {
      return false;
    }
  },
);
