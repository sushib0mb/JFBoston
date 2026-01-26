import 'package:flutter/material.dart';
import '../../../data/timetable_data.dart';
import 'package:provider/provider.dart';

class CurrentAndUpcomingEvents {
  final List<EventItem> currentStage1Events;
  final List<EventItem> currentStage2Events;
  final List<EventItem> upcomingStage1Events;
  final List<EventItem> upcomingStage2Events;

  CurrentAndUpcomingEvents({
    required this.currentStage1Events,
    required this.currentStage2Events,
    required this.upcomingStage1Events,
    required this.upcomingStage2Events,
  });
}

class LiveTimetable extends StatelessWidget {
  final double screenWidth;
  final int festivalStartYear;
  final int festivalStartMonth;
  final int festivalStartDay;
  final int festivalDays;
  final String festivalLocation;
  final int dayNumber;

  const LiveTimetable({
    super.key,
    required this.screenWidth,
    required this.festivalStartYear,
    required this.festivalStartMonth,
    required this.festivalStartDay,
    required this.festivalDays,
    required this.festivalLocation,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = screenWidth >= 600;
    final double sidePadding = isTablet ? 32.0 : 16.0;
    final double sectionSpacing = isTablet ? 24.0 : 16.0;
    final double statusFontSize = isTablet ? 18.0 : 16.0;

    final now = DateTime.now();

    // If not during festival, show appropriate message in place of live timetable
    if (dayNumber <= 0) {
      final festivalEnd = DateTime(
        festivalStartYear,
        festivalStartMonth,
        festivalStartDay,
      ).add(Duration(days: festivalDays - 1));

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Center(
            child: Text(
              dayNumber == -1
                  ? "See you at $festivalLocation on $festivalStartMonth/$festivalStartDay - ${festivalEnd.month}/${festivalEnd.day}!"
                  : "Thank you for visiting, and see you next year!",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Make sure schedule data exists before proceeding
      final scheduleService = Provider.of<ScheduleDataService>(context);
      final List<ScheduleItem> scheduleList;

      try {
        scheduleList = switch (dayNumber) {
          1 => scheduleService.day1ScheduleData,
          2 => scheduleService.day2ScheduleData,
          _ => [],
        };

        // Safety check - if schedule data is empty, show a message
        if (scheduleList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No schedule data available for  Day $dayNumber",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }
      } catch (e) {
        // Handle case where data is not available
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error loading schedule data: $e",
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
      }

      final currentAndUpcomingEvents = _getCurrentAndUpcomingEvents(
        scheduleList,
        now,
        dayNumber,
      );
      return Padding(
        padding: EdgeInsets.all(sidePadding),
        child: Column(
          children: [
            if (currentAndUpcomingEvents.currentStage1Events.isNotEmpty ||
                currentAndUpcomingEvents.currentStage2Events.isNotEmpty) ...[
              _buildEventSection(
                "🎤 Now Happening",
                currentAndUpcomingEvents.currentStage1Events,
                currentAndUpcomingEvents.currentStage2Events,
                screenWidth,
                isCurrent: true,
                isTablet: isTablet,
              ),
              SizedBox(height: sectionSpacing),
            ],
            if (currentAndUpcomingEvents.upcomingStage1Events.isNotEmpty ||
                currentAndUpcomingEvents.upcomingStage2Events.isNotEmpty) ...[
              _buildEventSection(
                "⏭️ Up Next",
                currentAndUpcomingEvents.upcomingStage1Events,
                currentAndUpcomingEvents.upcomingStage2Events,
                screenWidth,
                isCurrent: false,
                isTablet: isTablet,
              ),
              SizedBox(height: sectionSpacing),
            ],
            if (currentAndUpcomingEvents.currentStage1Events.isEmpty &&
                currentAndUpcomingEvents.currentStage2Events.isEmpty &&
                currentAndUpcomingEvents.upcomingStage1Events.isEmpty &&
                currentAndUpcomingEvents.upcomingStage2Events.isEmpty)
              Text(
                "No current or upcoming events at this time.",
                style: TextStyle(fontSize: statusFontSize),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }
  }

  CurrentAndUpcomingEvents _getCurrentAndUpcomingEvents(
    List<ScheduleItem> scheduleList,
    DateTime now,
    int dayNumber,
  ) {
    // Initialize empty lists for all categories
    List<EventItem> currentStage1Events = [];
    List<EventItem> currentStage2Events = [];
    List<EventItem> upcomingStage1Events = [];
    List<EventItem> upcomingStage2Events = [];

    // Current year and month
    final year = now.year;
    final month = now.month;
    final day = festivalStartDay + dayNumber - 1;

    // Process all events to find current and upcoming
    for (final item in scheduleList) {
      // Safety check - skip if stage events are null
      if (item.stage1Events == null && item.stage2Events == null) continue;

      // Process Stage 1 events
      if (item.stage1Events != null) {
        for (final event in item.stage1Events!) {
          // Skip if time format is invalid
          if (!event.time.contains(':')) continue;

          try {
            final eventTimeParts = event.time.split(":");
            final eventStartHour = int.parse(eventTimeParts[0]);
            final eventStartMinute = int.parse(eventTimeParts[1]);

            final tempDate = DateTime(
              2000,
              1,
              1,
              eventStartHour,
              eventStartMinute,
            );
            final tempEndDate = tempDate.add(Duration(minutes: event.duration));

            final eventEndHour = tempEndDate.hour;
            final eventEndMinute = tempEndDate.minute;

            final eventStart = DateTime(
              festivalStartYear,
              festivalStartMonth,
              festivalStartDay + event.day - 1,
              eventStartHour,
              eventStartMinute,
            );
            final eventEnd = DateTime(
              festivalStartYear,
              festivalStartMonth,
              festivalStartDay + event.day - 1,
              eventEndHour,
              eventEndMinute,
            );

            // Current event: now is between event start and end times
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentStage1Events.add(event);
            }
            // Upcoming event: event starts after now
            else if (eventStart.isAfter(now)) {
              // Only add if we don't have upcoming events yet or if this starts at the same time
              if (upcomingStage1Events.isEmpty ||
                  eventStart.isAtSameMomentAs(
                    _parseEventStartTime(
                      upcomingStage1Events.first.time,
                      year,
                      month,
                      day,
                    ),
                  )) {
                upcomingStage1Events.add(event);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Process Stage 2 events
      if (item.stage2Events != null) {
        for (final event in item.stage2Events!) {
          // Skip if time format is invalid
          if (!event.time.contains('-')) continue;

          try {
            // Parse the event time range (e.g., "11:00-11:15")
            final timeParts = event.time.split('-');
            final eventStartStr = timeParts[0].trim();
            final eventEndStr = timeParts[1].trim();

            // Convert to full DateTime objects
            final eventStartParts = eventStartStr.split(':');
            final eventEndParts = eventEndStr.split(':');

            if (eventStartParts.length != 2 || eventEndParts.length != 2)
              continue;

            final eventStartHour = int.parse(eventStartParts[0]);
            final eventStartMinute = int.parse(eventStartParts[1]);
            final eventEndHour = int.parse(eventEndParts[0]);
            final eventEndMinute = int.parse(eventEndParts[1]);

            final eventStart = DateTime(
              year,
              month,
              day,
              eventStartHour,
              eventStartMinute,
            );
            final eventEnd = DateTime(
              year,
              month,
              day,
              eventEndHour,
              eventEndMinute,
            );

            // Current event: now is between event start and end times
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentStage2Events.add(event);
            }
            // Upcoming event: event starts after now
            else if (eventStart.isAfter(now)) {
              // Only add if we don't have upcoming events yet or if this starts at the same time
              if (upcomingStage2Events.isEmpty ||
                  eventStart.isAtSameMomentAs(
                    _parseEventStartTime(
                      upcomingStage2Events.first.time,
                      year,
                      month,
                      day,
                    ),
                  )) {
                upcomingStage2Events.add(event);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    // Sort upcoming events by start time if we have multiple events
    if (upcomingStage1Events.length > 1) {
      upcomingStage1Events.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });
    }

    if (upcomingStage2Events.length > 1) {
      upcomingStage2Events.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });
    }

    // If we have multiple upcoming events with different start times, only keep the earliest ones
    if (upcomingStage1Events.isNotEmpty && upcomingStage2Events.isNotEmpty) {
      final stage1StartTime = _parseEventStartTime(
        upcomingStage1Events.first.time,
        year,
        month,
        day,
      );
      final stage2StartTime = _parseEventStartTime(
        upcomingStage2Events.first.time,
        year,
        month,
        day,
      );

      if (stage1StartTime.isBefore(stage2StartTime)) {
        // Keep only stage1 events that start at the earliest time
        upcomingStage2Events.clear();
      } else if (stage2StartTime.isBefore(stage1StartTime)) {
        // Keep only stage2 events that start at the earliest time
        upcomingStage1Events.clear();
      }
    }

    return CurrentAndUpcomingEvents(
      currentStage1Events: currentStage1Events,
      currentStage2Events: currentStage2Events,
      upcomingStage1Events: upcomingStage1Events,
      upcomingStage2Events: upcomingStage2Events,
    );
  }

  // Helper method to parse event start time from time range string with full date
  DateTime _parseEventStartTime(
    String timeRange,
    int year,
    int month,
    int day,
  ) {
    try {
      final timePart = timeRange.split('-')[0].trim();
      final parts = timePart.split(':');
      if (parts.length != 2) {
        // Return a default time far in the future if parsing fails
        return DateTime(9999);
      }
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      // Return a default time far in the future if parsing fails
      print('Error parsing event start time: $e');
      return DateTime(9999);
    }
  }

  // 2) EVENT SECTION
  Widget _buildEventSection(
    String title,
    List<EventItem> stage1Events,
    List<EventItem> stage2Events,
    double screenWidth, {
    required bool isCurrent,
    required bool isTablet,
  }) {
    final double titleFontSize = isTablet ? 24.0 : 20.0;
    final double spacing = isTablet ? 12.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
        ),
        SizedBox(height: spacing),
        ...stage1Events.map(
          (e) => _buildEventCard(e, isCurrent, screenWidth, isTablet),
        ),
        ...stage2Events.map(
          (e) => _buildEventCard(e, isCurrent, screenWidth, isTablet),
        ),
      ],
    );
  }

  // 3) EVENT CARD
  Widget _buildEventCard(
    EventItem event,
    bool isCurrent,
    double screenWidth,
    bool isTablet,
  ) {
    final double verticalPadding = isTablet ? 12.0 : 8.0;
    final EdgeInsets cardPadding = EdgeInsets.all(isTablet ? 24 : 16);
    final double borderRadius = isTablet ? 12.0 : 10.0;
    final double stageFontSize =
        screenWidth * (isTablet ? 0.055 : 0.045) + (isTablet ? 3 : 2);
    final double titleFontSize = screenWidth * (isTablet ? 0.055 : 0.045);
    final double iconDiameter = screenWidth * (isTablet ? 0.15 : 0.12);
    final double iconOffset = isTablet ? -20.0 : -18.0;
    final double iconPaddingLeft = isTablet ? 5.0 : 3.0;

    return GestureDetector(
      onTap: () {
        // TODO: Someone pasted llM shit here without putting the navigation logic
        // … your existing navigation logic …
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: cardPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: isTablet ? 8 : 5,
                    spreadRadius: isTablet ? 3 : 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage label
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      event.stage,
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: stageFontSize,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 5),
                  // Title
                  Text(
                    event.performanceName,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Time
                  Text(event.time, style: TextStyle(color: Colors.grey)),
                  // “Going on now” badge
                  if (isCurrent)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 8.0 : 5.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 6 : 4,
                          horizontal: isTablet ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Going on now!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating icon
            if (event.iconImage.isNotEmpty)
              Positioned(
                top: iconOffset,
                left: iconPaddingLeft,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: isTablet ? 6 : 5,
                        spreadRadius: isTablet ? 3 : 2,
                      ),
                    ],
                  ),
                  child: Image.network(
                    event.iconImage,
                    height: iconDiameter,
                    width: iconDiameter,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
