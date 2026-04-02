import 'dart:async';

import 'package:flutter/material.dart';
import '../home_page.dart';
import '../../../data/timetable_data.dart';
import 'package:provider/provider.dart';
import '../../../utils/time_utils.dart';

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
              style: const TextStyle(fontSize: 16),
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

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
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
            ],
            if (currentAndUpcomingEvents.upcomingStageEvents.isNotEmpty) ...[
              if (currentAndUpcomingEvents.currentStageEvents.isNotEmpty) ...[
                SizedBox(height: sectionSpacing),
              ],
              _buildEventSection(
                "⏭️ Up Next",
                currentAndUpcomingEvents.upcomingStageEvents,
                widget.screenWidth,
                isCurrent: false,
                isTablet: isTablet,
              ),
            ],
            if (currentAndUpcomingEvents.currentStageEvents.isEmpty &&
                currentAndUpcomingEvents.upcomingStageEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "No current or upcoming events at this time",
                    style: TextStyle(fontSize: statusFontSize),
                    textAlign: TextAlign.center,
                  ),
                ),
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

  // Categorize a list of events as current or upcoming
  void _categorizeEventList(
    List<EventItem>? events,
    DateTime now,
    int year,
    int month,
    int day,
    List<EventItem> currentEvents,
    List<EventItem> upcomingEvents,
  ) {
    if (events == null) return;

    for (final event in events) {
      // Skip placeholder events (empty performance names)
      if (event.performanceName.isEmpty || !event.time.contains(':')) continue;

      try {
        final times = calculateEventTimes(event, year, month, day);

        // Categorize as current or upcoming
        if (now.isAfter(times.start) && now.isBefore(times.end)) {
          currentEvents.add(event);
        } else if (times.start.isAfter(now)) {
          upcomingEvents.add(event);
        }
      } catch (e) {
        continue;
      }
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
      // Skip if the dynamic map is empty
      if (item.eventsByStage.isEmpty) continue;

      // Iterate through EVERY stage list dynamically
      for (final eventList in item.eventsByStage.values) {
        // If the list is null or empty, skip it
        if (eventList.isEmpty) continue;

        _categorizeEventList(
          eventList,
          now,
          year,
          month,
          day,
          currentEvents,
          upcomingEvents,
        );
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

  // Format countdown time as "HHh MMm" or "MMm"
  String _formatCountdownTime(DateTime eventStart) {
    final now = DateTime.now();
    final difference = eventStart.difference(now);
    final totalMinutes = difference.inMinutes;

    if (totalMinutes <= 0) return "0m";

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return "${minutes}m";
    } else if (minutes == 0) {
      return "${hours}h";
    } else {
      return "${hours}h ${minutes}m";
    }
  }

  // Get badge color based on remaining minutes
  Color _getCountdownBadgeColor(int remainingMinutes) {
    if (remainingMinutes > 60) {
      return const Color.fromARGB(255, 154, 190, 118);
    } else if (remainingMinutes >= 10) {
      return const Color.fromARGB(255, 240, 192, 32);
    } else {
      return const Color.fromARGB(255, 240, 129, 121);
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

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = widget.festivalStartDay + widget.dayNumber - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 8,
            vertical: isTablet ? 7 : 5,
          ),
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
        ...events.map((e) {
          final eventStartDateTime = _parseEventStartTime(
            e.time,
            year,
            month,
            day,
          );
          return _buildEventCard(
            e,
            isCurrent,
            screenWidth,
            isTablet,
            eventStartDateTime,
          );
        }),
      ],
    );
  }

  // 3) EVENT CARD
  Widget _buildEventCard(
    EventItem event,
    bool isCurrent,
    double screenWidth,
    bool isTablet,
    DateTime eventStartDateTime,
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
                  Text(
                    (calculateEventTimes(
                      event,
                      festivalStartYear,
                      festivalStartMonth,
                      festivalStartDay + festivalDays - 1,
                      returnAsString: true,
                    )),
                    style: TextStyle(color: Colors.grey),
                  ),
                  // “Going on now” badge
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 8.0 : 5.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 6 : 4,
                        horizontal: isTablet ? 12 : 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCurrent
                                ? Colors.orange
                                : _getCountdownBadgeColor(
                                  eventStartDateTime
                                      .difference(DateTime.now())
                                      .inMinutes,
                                ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCurrent
                            ? "Going on now!"
                            : "Starts in ${_formatCountdownTime(eventStartDateTime)}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 14,
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
