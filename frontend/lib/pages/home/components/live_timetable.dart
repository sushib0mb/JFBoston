import 'dart:async';
import 'package:flutter/material.dart';
import '../../../main.dart';
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

  // ── Layout Constants (Unified & Clean) ───────────────────────────────────
  static const double _sectionSpacing = 16.0;
  static const double _statusFontSize = 16.0;
  static const double _sectionTitleFont = 20.0;
  static const double _cardVerticalPad = 8.0;
  static const double _cardPadding = 16.0;
  static const double _cardBorderRadius = 12.0;
  static const double _stageLabelFontSize = 14.0;
  static const double _eventTitleFontSize = 18.0;
  static const double _iconDiameter = 50.0;
  static const double _iconOffset = -18.0;
  static const double _badgeFontSize = 14.0;

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
    final now = DateTime.now();

    // 1. Check if festival is active
    if (widget.dayNumber <= 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        child: _buildMessageCard(
          widget.dayNumber == -1
              ? "See you at ${widget.festivalLocation}!"
              : "Thank you for visiting, and see you next year!",
        ),
      );
    }

    // 2. Load Schedule Data
    final scheduleService = Provider.of<ScheduleDataService>(context);
    final List<ScheduleItem> scheduleList =
        widget.dayNumber == 1
            ? scheduleService.day1ScheduleData
            : scheduleService.day2ScheduleData;

    if (scheduleList.isEmpty) {
      return _buildMessageCard(
        "No schedule data available for Day ${widget.dayNumber}",
      );
    }

    final events = _getCurrentAndUpcomingEvents(scheduleList, now);

    return Column(
      children: [
        if (events.currentStageEvents.isNotEmpty)
          _buildEventSection(
            "Now Happening",
            events.currentStageEvents,
            isCurrent: true,
          ),

        if (events.currentStageEvents.isNotEmpty &&
            events.upcomingStageEvents.isNotEmpty)
          const SizedBox(height: _sectionSpacing),

        if (events.upcomingStageEvents.isNotEmpty)
          _buildEventSection(
            "Up Next",
            events.upcomingStageEvents,
            isCurrent: false,
          ),

        if (events.currentStageEvents.isEmpty &&
            events.upcomingStageEvents.isEmpty)
          _buildMessageCard("No events scheduled for the rest of today."),
      ],
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────

  Widget _buildMessageCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _cardVerticalPad),
      child: Container(
        padding: const EdgeInsets.all(_cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: _statusFontSize),
          ),
        ),
      ),
    );
  }

  Widget _buildEventSection(
    String title,
    List<EventItem> events, {
    required bool isCurrent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: _sectionTitleFont,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...events.map((e) => _buildEventCard(e, isCurrent)),
      ],
    );
  }

  Widget _buildEventCard(EventItem event, bool isCurrent) {
    final now = DateTime.now();
    final eventStart = _parseEventStartTime(
      event.time,
      now.year,
      now.month,
      widget.festivalStartDay + widget.dayNumber - 1,
    );

    return GestureDetector(
      onTap:
          () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => MainScreen(
                    initialIndex: 2,
                    selectedEvent: event,
                    selectedDay: widget.dayNumber,
                    initialStage: event.stage,
                  ),
            ),
            (route) => false,
          ),
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
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage Pill Label
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStageColor(event.stage),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        event.stage,
                        style: const TextStyle(
                          fontSize: _stageLabelFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.performanceName,
                    style: const TextStyle(
                      fontSize: _eventTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(event.time, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCurrent
                              ? Colors.orange
                              : _getCountdownColor(
                                eventStart.difference(now).inMinutes,
                              ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCurrent
                          ? "Going on now!"
                          : "Starts in ${_formatCountdown(eventStart)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: _badgeFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Floating Icon
            if (event.iconImage.isNotEmpty)
              Positioned(
                top: _iconOffset,
                left: 3,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _getStageColor(String stage) {
    if (stage == "Main Stage") return Colors.green.shade100;
    if (stage == "Sakura Stage") return Colors.red.shade100;
    return Colors.blue.shade100;
  }

  Color _getCountdownColor(int mins) {
    if (mins > 60) return const Color(0xFF9ABE76);
    if (mins >= 10) return const Color(0xFFF0C020);
    return const Color(0xFFF08179);
  }

  String _formatCountdown(DateTime start) {
    final diff = start.difference(DateTime.now());
    if (diff.inMinutes <= 0) return "0m";
    return diff.inHours > 0
        ? "${diff.inHours}h ${diff.inMinutes % 60}m"
        : "${diff.inMinutes}m";
  }

  DateTime _parseEventStartTime(String timeStr, int y, int m, int d) {
    try {
      final parts = timeStr.split(':');
      return DateTime(y, m, d, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime(9999);
    }
  }

  CurrentAndUpcomingEvents _getCurrentAndUpcomingEvents(
    List<ScheduleItem> list,
    DateTime now,
  ) {
    if (_cache.isCacheValid(now)) return _cache.cachedEvents!;

    final current = <EventItem>[];
    final upcoming = <EventItem>[];
    final day = widget.festivalStartDay + widget.dayNumber - 1;

    for (var item in list) {
      for (var eventList in item.eventsByStage.values) {
        for (var event in eventList) {
          if (event.performanceName.isEmpty) continue;
          final times = calculateEventTimes(event, now.year, now.month, day);
          if (now.isAfter(times.start) && now.isBefore(times.end)) {
            current.add(event);
          } else if (times.start.isAfter(now)) {
            upcoming.add(event);
          }
        }
      }
    }

    // Sort upcoming and filter to just the "Next" block
    if (upcoming.isNotEmpty) {
      upcoming.sort(
        (a, b) => _parseEventStartTime(
          a.time,
          now.year,
          now.month,
          day,
        ).compareTo(_parseEventStartTime(b.time, now.year, now.month, day)),
      );
      final nextTime = upcoming.first.time;
      upcoming.removeWhere((e) => e.time != nextTime);
    }

    final result = CurrentAndUpcomingEvents(
      currentStageEvents: current,
      upcomingStageEvents: upcoming,
    );
    _cache.updateCache(result, now);
    return result;
  }
}
