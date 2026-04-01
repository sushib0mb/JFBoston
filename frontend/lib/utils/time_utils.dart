import '../data/timetable_data.dart';

// Takes in a time as a string and an int duration and adds the duration to the time
String findEndTime(String time, int duration) {
  List<String> timeSplit = time.split(":");

  int addHr = (duration / 60).floor();
  int addMin = duration % 60;

  int currentHr = int.parse(timeSplit[0]);
  int currentMin = int.parse(timeSplit[1]);

  int totalMin = currentMin + addMin;
  int extraHr = totalMin ~/ 60; // Integer division to get hours from minutes
  int finalMin = totalMin % 60; // Remaining minutes

  int totalHr = currentHr + addHr + extraHr;
  int finalHr = totalHr % 24; // Keeps the hour between 0 and 23

  String formattedHr = finalHr.toString().padLeft(2, '0');
  String formattedMin = finalMin.toString().padLeft(2, '0');

  return "$formattedHr:$formattedMin";
}

// Calculate event start and end times from event time and duration, with regards to date
T calculateEventTimes<T>(
  EventItem event,
  int year,
  int month,
  int day, {
  bool returnAsString = false,
}) {
  final eventTimeParts = event.time.split(':');
  final eventStartHour = int.parse(eventTimeParts[0]);
  final eventStartMinute = int.parse(eventTimeParts[1]);

  final start = DateTime(year, month, day, eventStartHour, eventStartMinute);
  final end = start.add(Duration(minutes: event.duration));

  if (returnAsString) {
    String startTime =
        "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
    String endTime =
        "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
    return ("$startTime - $endTime") as T;
  }

  return (start: start, end: end) as T;
}

// Converts time string into int minutes
int parseTimeToMinutes(String timeString) {
  try {
    final hourAndMinute = timeString.split(':');
    int hour = int.parse(hourAndMinute[0]);
    final int minute =
        hourAndMinute.length > 1 ? int.parse(hourAndMinute[1]) : 0;

    final isPM = int.tryParse(hourAndMinute[0])! >= 12;

    // Convert to 24-hour format if PM
    if (isPM && hour < 12) {
      hour += 12;
    }
    // Handle 12 AM edge case
    if (!isPM && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  } catch (e) {
    return 0; // Default fallback
  }
}
