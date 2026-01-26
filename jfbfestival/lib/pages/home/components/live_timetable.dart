import 'dart:async';

import 'package:flutter/material.dart';
import '../../../data/timetable_data.dart';
import 'package:provider/provider.dart';

class CurrentAndUpcomingEvents {
  final List<EventItem> currentStageEvents;
  final List<EventItem> upcomingStageEvents;

  CurrentAndUpcomingEvents({
    required this.currentStageEvents,
    required this.upcomingStageEvents,
  });
}

class _EventCache {
  CurrentAndUpcomingEvents? cachedEvents;
  DateTime lastCalculationTime = DateTime(2000);

  bool isCacheValid(DateTime now) {
    if (cachedEvents == null) return false;
    final secondsSinceLastCalculation =
        now.difference(lastCalculationTime).inSeconds;
    return secondsSinceLastCalculation < 60;
  }

  void invalidate() {
    cachedEvents = null;
    lastCalculationTime = DateTime(2000);
  }

  void updateCache(CurrentAndUpcomingEvents events, DateTime now) {
    cachedEvents = events;
    lastCalculationTime = now;
  }
}

class LiveTimetable extends StatefulWidget {
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
  State<LiveTimetable> createState() => _LiveTimetableState();
}

class _LiveTimetableState extends State<LiveTimetable> {
  late _EventCache _cache;
  late Timer _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _cache = _EventCache();
    // Set up fallback timer to recalculate events every minute
    _fallbackTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _fallbackTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = widget.screenWidth >= 600;
    final double sidePadding = isTablet ? 32.0 : 16.0;
    final double sectionSpacing = isTablet ? 24.0 : 16.0;
    final double statusFontSize = isTablet ? 18.0 : 16.0;

    final now = DateTime.now();

    // If not during festival, show appropriate message
    if (widget.dayNumber <= 0) {
      final festivalEnd = DateTime(
        widget.festivalStartYear,
        widget.festivalStartMonth,
        widget.festivalStartDay,
      ).add(Duration(days: widget.festivalDays - 1));

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
              widget.dayNumber == -1
                  ? "See you at ${widget.festivalLocation} on ${widget.festivalStartMonth}/${widget.festivalStartDay} - ${festivalEnd.month}/${festivalEnd.day}!"
                  : "Thank you for visiting, and see you next year!",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Get schedule service with listener for data changes
      final scheduleService = Provider.of<ScheduleDataService>(
        context,
        listen: true,
      );
      final List<ScheduleItem> scheduleList;

      try {
        scheduleList = switch (widget.dayNumber) {
          1 => scheduleService.day1ScheduleData,
          2 => scheduleService.day2ScheduleData,
          _ => [],
        };

        // Invalidate cache if schedule data changed
        _cache.invalidate();

        // Safety check - if schedule data is empty, show a message
        if (scheduleList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No schedule data available for Day ${widget.dayNumber}",
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
      );

      return Padding(
        padding: EdgeInsets.all(sidePadding),
        child: Column(
          children: [
            if (currentAndUpcomingEvents.currentStageEvents.isNotEmpty) ...[
              _buildEventSection(
                "🎤 Now Happening",
                currentAndUpcomingEvents.currentStageEvents,
                widget.screenWidth,
                isCurrent: true,
                isTablet: isTablet,
              ),
              SizedBox(height: sectionSpacing),
            ],
            if (currentAndUpcomingEvents.upcomingStageEvents.isNotEmpty) ...[
              _buildEventSection(
                "⏭️ Up Next",
                currentAndUpcomingEvents.upcomingStageEvents,
                widget.screenWidth,
                isCurrent: false,
                isTablet: isTablet,
              ),
              SizedBox(height: sectionSpacing),
            ],
            if (currentAndUpcomingEvents.currentStageEvents.isEmpty &&
                currentAndUpcomingEvents.upcomingStageEvents.isEmpty)
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
  ) {
    // Check cache first
    if (_cache.isCacheValid(now)) {
      return _cache.cachedEvents!;
    }

    // Cache miss - calculate current and upcoming events
    final currentEvents = <EventItem>[];
    final upcomingEvents = <EventItem>[];

    _processEvents(scheduleList, now, currentEvents, upcomingEvents);

    // Create and cache result
    final result = CurrentAndUpcomingEvents(
      currentStageEvents: currentEvents,
      upcomingStageEvents: upcomingEvents,
    );

    _cache.updateCache(result, now);
    return result;
  }

  // Helper method to parse event start time from time string with full date
  DateTime _parseEventStartTime(String timeStr, int year, int month, int day) {
    try {
      final parts = timeStr.split(':');
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

  // Process events from all stages and categorize them as current or upcoming
  void _processEvents(
    List<ScheduleItem> scheduleList,
    DateTime now,
    List<EventItem> currentEvents,
    List<EventItem> upcomingEvents,
  ) {
    currentEvents.clear();
    upcomingEvents.clear();

    final year = now.year;
    final month = now.month;
    final day = widget.festivalStartDay + widget.dayNumber - 1;

    // Process all events from all schedule items
    for (final item in scheduleList) {
      if (item.stage1Events == null && item.stage2Events == null) continue;

      // Process stage 1 events
      if (item.stage1Events != null) {
        for (final event in item.stage1Events!) {
          // Skip placeholder events (empty performance names)
          if (event.performanceName.isEmpty || !event.time.contains(':'))
            continue;

          try {
            final eventTimeParts = event.time.split(':');
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
              widget.festivalStartYear,
              widget.festivalStartMonth,
              widget.festivalStartDay + event.day - 1,
              eventStartHour,
              eventStartMinute,
            );
            final eventEnd = DateTime(
              widget.festivalStartYear,
              widget.festivalStartMonth,
              widget.festivalStartDay + event.day - 1,
              eventEndHour,
              eventEndMinute,
            );

            // Categorize as current or upcoming
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentEvents.add(event);
            } else if (eventStart.isAfter(now)) {
              upcomingEvents.add(event);
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Process stage 2 events
      if (item.stage2Events != null) {
        for (final event in item.stage2Events!) {
          // Skip placeholder events (empty performance names)
          if (event.performanceName.isEmpty || !event.time.contains(':'))
            continue;

          try {
            final eventTimeParts = event.time.split(':');
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

            // Categorize as current or upcoming
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentEvents.add(event);
            } else if (eventStart.isAfter(now)) {
              upcomingEvents.add(event);
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    // Sort upcoming events by start time
    if (upcomingEvents.length > 1) {
      upcomingEvents.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });

      // Keep only the earliest batch of upcoming events
      final firstEventTime = _parseEventStartTime(
        upcomingEvents.first.time,
        year,
        month,
        day,
      );
      upcomingEvents.removeWhere((event) {
        final eventTime = _parseEventStartTime(event.time, year, month, day);
        return !eventTime.isAtSameMomentAs(firstEventTime);
      });
    }
  }

  // Build event section with title and list of events
  Widget _buildEventSection(
    String title,
    List<EventItem> events,
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
        ...events.map(
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
