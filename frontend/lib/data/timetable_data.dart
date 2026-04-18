import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../../pages/home/home_page.dart';

class FestivalDates {
  static DateTime forDay(int day) => DateTime(
    festivalStartYear,
    festivalStartMonth,
    festivalStartDay + (day - 1),
  );
}

// Event item model
class EventItem {
  final int id;
  final String performanceName;
  final String time; // actual start time in HH:MM format
  final String groupTime; // 30-minute bracket in HH:MM format (xx:00 or xx:30)
  final String iconImage;
  final int duration; // in minutes
  final String stage;
  final String description;
  final String eventImage;
  final int day;

  EventItem({
    required this.id,
    required this.performanceName,
    required this.time,
    required this.groupTime,
    required this.duration,
    required this.iconImage,
    required this.stage,
    required this.description,
    required this.eventImage,
    required this.day,
  });

  /// Full [DateTime] when this event starts, based on [FestivalDates].
  DateTime get startDateTime {
    final base = FestivalDates.forDay(day);
    final parts = time.split(':');
    if (parts.length < 2) return base;
    return DateTime(
      base.year,
      base.month,
      base.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  factory EventItem.fromSupabase(Map<String, dynamic> data) {
    String rawTime = data['time'] ?? '';
    final String timetz =
        rawTime.contains(':') ? rawTime.split(':').take(2).join(':') : rawTime;
    final String groupTime = _calculateGroupTime(timetz);

    return EventItem(
      id: data['id'] ?? 0,
      performanceName: data['performance_name'] ?? '',
      time: timetz,
      groupTime: groupTime,
      duration: data['duration'] ?? 0,
      iconImage: data['icon_image'] ?? '',
      stage: data['stage'] ?? '',
      description: data['description'] ?? '',
      eventImage: data['event_image'] ?? '',
      day: data['day'] ?? 0,
    );
  }

  // Calculate 30-minute bracket (floor to nearest xx:00 or xx:30)
  static String _calculateGroupTime(String time) {
    if (time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Floor to nearest 30-minute bracket
    if (minute < 30) {
      return '${hour.toString().padLeft(2, '0')}:00';
    } else {
      return '${hour.toString().padLeft(2, '0')}:30';
    }
  }
}

// Schedule item model
class ScheduleItem {
  final String time;
  // A dynamic map holding all stages! e.g., {'Main Stage': [event1], 'Downtown 1': [event2]}
  final Map<String, List<EventItem>> eventsByStage;

  ScheduleItem({required this.time, required this.eventsByStage});
}

// Service to manage schedule data
class ScheduleDataService extends ChangeNotifier {
  // Supabase client
  final SupabaseClient _supabase;

  // Stage options: Add new stages here
  static const List<String> stageNames = [
    'Main Stage',
    'Sakura Stage',
    'Fuji Stage',
  ];

  // Data storage
  List<ScheduleItem> day1ScheduleData = [];
  List<ScheduleItem> day2ScheduleData = [];

  // State variables
  bool isLoading = false;
  String? errorMessage;

  // Realtime channel
  RealtimeChannel? _realtimeChannel;

  // Constructor
  ScheduleDataService(this._supabase) {
    refreshAllData();
    _setupRealtimeListener();
  }

  Future<void> refreshAllData() async {
    try {
      isLoading = true;
      notifyListeners();

      final List<dynamic> response = await _supabase
          .from("stage_events")
          .select()
          .order('time');

      final allEvents = List<Map<String, dynamic>>.from(response);

      day1ScheduleData = _processEventData(
        allEvents.where((e) => e['day'] == 1).toList(),
      );
      day2ScheduleData = _processEventData(
        allEvents.where((e) => e['day'] == 2).toList(),
      );

      errorMessage = null;
    } catch (e) {
      print("error: $e");
      errorMessage = "Error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeListener() {
    _realtimeChannel = _supabase.channel('schedule_updates');

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stage_events',
          callback: (payload) {
            refreshAllData();
          },
        )
        .subscribe();
  }

  // Utility: Convert HH:MM format to minutes since midnight
  int _timeToMinutes(String time) {
    if (time.isEmpty) return 0;
    final parts = time.split(':');
    if (parts.length < 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  // Process event data into schedule items with 30-minute brackets
  List<ScheduleItem> _processEventData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return [];
    }

    // Convert all events and group by groupTime
    List<EventItem> allEvents = [];
    Map<String, Map<String, List<EventItem>>> groupedByBracket = {};

    // Add all events into their respective group times
    for (var item in data) {
      EventItem event = EventItem.fromSupabase(item);
      allEvents.add(event);

      // Dynamically initialize the bracket map for all known stages
      groupedByBracket.putIfAbsent(event.groupTime, () {
        Map<String, List<EventItem>> stageMap = {};
        for (var stage in stageNames) {
          stageMap[stage] = [];
        }
        return stageMap;
      });

      // Dynamically add the event to its matching stage list
      if (groupedByBracket[event.groupTime]!.containsKey(event.stage)) {
        groupedByBracket[event.groupTime]![event.stage]!.add(event);
      }
    }

    // Calculate floor of first event and ceil of last event in minutes
    int minMinutes = allEvents
        .map((e) => _timeToMinutes(e.time))
        .reduce((a, b) => a < b ? a : b);
    int maxMinutes = allEvents
        .map((e) => _timeToMinutes(e.time) + e.duration)
        .reduce((a, b) => a > b ? a : b);

    // Floor first time to nearest bracket
    int floorMinutes = (minMinutes ~/ 30) * 30;

    // Ceil last time to nearest bracket
    int ceilMinutes = (maxMinutes ~/ 30) * 30;

    // Generate all 30-minute brackets
    List<String> allBrackets = [];
    for (int m = floorMinutes; m <= ceilMinutes; m += 30) {
      final hour = m ~/ 60;
      final minute = m % 60;
      final bracket =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      allBrackets.add(bracket);
    }

    // Create ScheduleItems for all brackets
    List<ScheduleItem> scheduleItems = [];
    for (int i = 0; i < allBrackets.length; i++) {
      final bracket = allBrackets[i];
      final bracketEvents = groupedByBracket[bracket];

      // Check if this bracket is completely empty across ALL stages
      bool isBracketCompletelyEmpty = true;
      if (bracketEvents != null) {
        for (var stageList in bracketEvents.values) {
          if (stageList.isNotEmpty) {
            isBracketCompletelyEmpty = false;
            break;
          }
        }
      }

      Map<String, List<EventItem>> finalStageEventsForBracket = {};

      if (isBracketCompletelyEmpty) {
        int nextEventMinutes = ceilMinutes + 30;
        for (var event in allEvents) {
          final eventMinutes = _timeToMinutes(event.time);
          if (eventMinutes > _timeToMinutes(bracket)) {
            nextEventMinutes = eventMinutes;
            break;
          }
        }

        final durationToNextEvent = nextEventMinutes - _timeToMinutes(bracket);

        // Dynamically create an empty placeholder block for EVERY known stage
        for (var stage in stageNames) {
          finalStageEventsForBracket[stage] = [
            EventItem(
              id: -1,
              performanceName: '',
              time: bracket,
              groupTime: bracket,
              duration: durationToNextEvent,
              iconImage: '',
              stage: stage,
              description: '',
              eventImage: '',
              day: -1,
            ),
          ];
        }
      } else {
        // Only attach stages that actually have events (or you can attach empty lists if your UI prefers)
        for (var stage in stageNames) {
          var eventsList = bracketEvents?[stage] ?? [];
          if (eventsList.isNotEmpty) {
            finalStageEventsForBracket[stage] = eventsList;
          }
        }
      }

      scheduleItems.add(
        ScheduleItem(time: bracket, eventsByStage: finalStageEventsForBracket),
      );
    }

    return scheduleItems;
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
