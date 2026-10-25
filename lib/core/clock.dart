/// "Now" for anything the UI shows relative to the present (today/this
/// week labels, past-due states). Tests freeze it so screenshots don't
/// change with the calendar; the app never reassigns it.
DateTime Function() clockNow = DateTime.now;
