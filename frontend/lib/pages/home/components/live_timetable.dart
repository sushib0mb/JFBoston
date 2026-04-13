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
    return now.difference(lastCalculationTime).inSeconds < 60;
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
  // ── screenWidth removed — no screen-size param needed ────────────────────
  final int festivalStartYear;
  final int festivalStartMonth;
  final int festivalStartDay;
  final int festivalDays;
  final String festivalLocation;
  final int dayNumber;

  const LiveTimetable({
    super.key,
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

  // ── All fixed constants — no screen-size math anywhere ───────────────────
  static const double _sectionSpacing       = 16.0;
  static const double _statusFontSize       = 16.0;
  static const double _sectionTitleFont     = 20.0;
  static const double _sectionTitleHPad     = 8.0;
  static const double _sectionTitleVPad     = 5.0;
  static const double _sectionTitleSpacing  = 8.0;
  static const double _cardVerticalPad      = 8.0;
  static const double _cardPadding          = 16.0;
  static const double _cardBorderRadius     = 10.0;
  static const double _stageFontSize        = 18.0;  // was screenWidth*0.045+2
  static const double _eventTitleFontSize   = 16.0;  // was screenWidth*0.045
  static const double _iconDiameter         = 44.0;  // was screenWidth*0.12
  static const double _iconOffset           = -18.0;
  static const double _iconPaddingLeft      = 3.0;
  static const double _iconInnerPadding     = 6.0;
  static const double _badgeFontSize        = 14.0;
  static const double _badgeVerticalPad     = 4.0;
  static const double _badgeHorizontalPad   = 8.0;
  static const double _badgeTopPad          = 5.0;
  static const double _stageNameTopPad      = 5.0;

  @override
  void initState() {
    super.initState();
    _cache = _EventCache();
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
    // ── isTablet, sectionSpacing, statusFontSize variables removed ────────
    final now = DateTime.now();

    // Not during festival
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
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Center(
            child: Text(
              widget.dayNumber == -1
                  ? "See you at ${widget.festivalLocation} on "
                    "${widget.festivalStartMonth}/${widget.festivalStartDay}"
                    " - ${festivalEnd.month}/${festivalEnd.day}!"
                  : "Thank you for visiting, and see you next year!",
              style: const TextStyle(fontSize: _statusFontSize),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // During festival
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

      _cache.invalidate();

      if (scheduleList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No schedule data available for Day ${widget.dayNumber}",
            style: const TextStyle(fontSize: _statusFontSize),
            textAlign: TextAlign.center,
          ),
        );
      }
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Error loading schedule data: $e",
          style: const TextStyle(fontSize: _statusFontSize, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    final currentAndUpcomingEvents =
        _getCurrentAndUpcomingEvents(scheduleList, now);

    final hasCurrent =
        currentAndUpcomingEvents.currentStageEvents.isNotEmpty;
    final hasUpcoming =
        currentAndUpcomingEvents.upcomingStageEvents.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Now happening
          if (hasCurrent)
            _buildEventSection(
              "🎤 Now Happening",
              currentAndUpcomingEvents.currentStageEvents,
              isCurrent: true,
            ),

          // Spacer between sections
          if (hasCurrent && hasUpcoming)
            const SizedBox(height: _sectionSpacing),

          // Up next
          if (hasUpcoming)
            _buildEventSection(
              "⏭️ Up Next",
              currentAndUpcomingEvents.upcomingStageEvents,
              isCurrent: false,
            ),

          // Nothing on
          if (!hasCurrent && !hasUpcoming)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "No current or upcoming events at this time",
                  style: TextStyle(fontSize: _statusFontSize),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logic helpers (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  CurrentAndUpcomingEvents _getCurrentAndUpcomingEvents(
    List<ScheduleItem> scheduleList,
    DateTime now,
  ) {
    if (_cache.isCacheValid(now)) return _cache.cachedEvents!;

    final currentEvents = <EventItem>[];
    final upcomingEvents = <EventItem>[];
    _processEvents(scheduleList, now, currentEvents, upcomingEvents);

    final result = CurrentAndUpcomingEvents(
      currentStageEvents: currentEvents,
      upcomingStageEvents: upcomingEvents,
    );
    _cache.updateCache(result, now);
    return result;
  }

  DateTime _parseEventStartTime(
      String timeStr, int year, int month, int day) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return DateTime(9999);
      return DateTime(year, month, day,
          int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return DateTime(9999);
    }
  }

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
      if (event.performanceName.isEmpty || !event.time.contains(':')) continue;
      try {
        final times = calculateEventTimes(event, year, month, day);
        if (now.isAfter(times.start) && now.isBefore(times.end)) {
          currentEvents.add(event);
        } else if (times.start.isAfter(now)) {
          upcomingEvents.add(event);
        }
      } catch (_) {
        continue;
      }
    }
  }

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

    for (final item in scheduleList) {
      if (item.eventsByStage.isEmpty) continue;
      for (final eventList in item.eventsByStage.values) {
        if (eventList.isEmpty) continue;
        _categorizeEventList(
            eventList, now, year, month, day, currentEvents, upcomingEvents);
      }
    }

    if (upcomingEvents.length > 1) {
      upcomingEvents.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });

      final firstEventTime = _parseEventStartTime(
          upcomingEvents.first.time, year, month, day);
      upcomingEvents.removeWhere((event) {
        final eventTime =
            _parseEventStartTime(event.time, year, month, day);
        return !eventTime.isAtSameMomentAs(firstEventTime);
      });
    }
  }

  String _formatCountdownTime(DateTime eventStart) {
    final totalMinutes = eventStart.difference(DateTime.now()).inMinutes;
    if (totalMinutes <= 0) return "0m";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return "${minutes}m";
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  Color _getCountdownBadgeColor(int remainingMinutes) {
    if (remainingMinutes > 60) return const Color.fromARGB(255, 154, 190, 118);
    if (remainingMinutes >= 10) return const Color.fromARGB(255, 240, 192, 32);
    return const Color.fromARGB(255, 240, 129, 121);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI builders — all screenWidth/isTablet params removed
  // ─────────────────────────────────────────────────────────────────────────

  // ── screenWidth, isTablet params removed ─────────────────────────────────
  Widget _buildEventSection(
    String title,
    List<EventItem> events, {
    required bool isCurrent,
  }) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = widget.festivalStartDay + widget.dayNumber - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _sectionTitleHPad,
            vertical: _sectionTitleVPad,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: _sectionTitleFont,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
        ),
        const SizedBox(height: _sectionTitleSpacing),
        ...events.map((e) {
          final eventStartDateTime =
              _parseEventStartTime(e.time, year, month, day);
          return _buildEventCard(e, isCurrent, eventStartDateTime);
        }),
      ],
    );
  }

  // ── screenWidth and isTablet params removed — all sizes use static consts ─
  Widget _buildEventCard(
    EventItem event,
    bool isCurrent,
    DateTime eventStartDateTime,
  ) {
    return GestureDetector(
      onTap: () {
        // TODO: navigation logic
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _cardVerticalPad),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(_cardPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_cardBorderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 2,
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
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: _stageFontSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: _stageNameTopPad),

                  // Performance title
                  Text(
                    event.performanceName,
                    style: const TextStyle(
                      fontSize: _eventTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Time range string
                  Text(
                    calculateEventTimes(
                      event,
                      widget.festivalStartYear,
                      widget.festivalStartMonth,
                      widget.festivalStartDay + widget.festivalDays - 1,
                      returnAsString: true,
                    ),
                    style: const TextStyle(color: Colors.grey),
                  ),

                  // Live / countdown badge
                  Padding(
                    padding: const EdgeInsets.only(top: _badgeTopPad),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: _badgeVerticalPad,
                        horizontal: _badgeHorizontalPad,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: _badgeFontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating icon — fixed constants, no screenWidth math
            if (event.iconImage.isNotEmpty)
              Positioned(
                top: _iconOffset,
                left: _iconPaddingLeft,
                child: Container(
                  padding: const EdgeInsets.all(_iconInnerPadding),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.network(
                    event.iconImage,
                    height: _iconDiameter,
                    width: _iconDiameter,
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