import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../data/timetable_data.dart'; // Ensure this import still exists if needed for other reasons
// import 'package:flutter/foundation.dart' show kDebugMode; // Removed debug mode import
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

class ReminderProvider extends ChangeNotifier {
  bool _enabled = false;
  bool _loaded = false;
  bool get enabled => _enabled;
  bool get isLoaded => _loaded;

  final _notifier = NotificationService();

  ReminderProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('reminders') ?? false;
    _loaded = true;
    notifyListeners();

    await _notifier.init();
  }

  Future<void> toggle(BuildContext context) async {
    if (!_enabled && Platform.isIOS) {
      await _notifier.requestPermissions();
    }
    await _setEnabled(!_enabled, context);
  }

  Future<void> _setEnabled(bool v, BuildContext context) async {
    _enabled = v;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders', v);

    if (v) {
      if (Platform.isIOS) {
        await _notifier.requestPermissions();
      }

      final scheduleService = Provider.of<ScheduleDataService>(
        context,
        listen: false,
      );
      unawaited(_scheduleAll(scheduleService));
    } else {
      unawaited(_notifier.cancelAll());
    }
  }

  Future<void> _scheduleAll(ScheduleDataService scheduleService) async {
    await _notifier.cancelAll();
    int id = 0;

    // // For debugging purposes
    // if (kDebugMode) {
    //   await _notifier.cancelAll();
    //
    //   // Simulated current time: April 26, 2025 at 1:15 PM (UTC-4)
    //   final simulatedNow = tz.TZDateTime(tz.local, 2025, 4, 27, 13, 15);
    //   debugPrint('⏱ Simulated current time: $simulatedNow');
    //
    //   debugPrint('🗓️ Day 2 Schedule Data: ${scheduleService.day2ScheduleData.map((item) => item.time).toList()}');
    //
    //   final matchingItemDay2 = scheduleService.day2ScheduleData.firstWhere(
    //     (item) => item.time.trim() == "1:00 pm",
    //     orElse: () {
    //       debugPrint("❌ No Day 2 ScheduleItem found for '1:00 pm'");
    //       throw Exception("❌ No Day 2 ScheduleItem found for '1:00 pm'");
    //     },
    //   );
    //
    //   debugPrint('🔍 Matching Day 2 Item: ${matchingItemDay2.time}, Stage 1 Events: ${matchingItemDay2.stage1Events?.map((e) => e.time).toList()}, Stage 2 Events: ${matchingItemDay2.stage2Events?.map((e) => e.time).toList()}');
    //
    //   final eventDay2 = matchingItemDay2.stage1Events!.firstWhere(
    //     (e) => e.time.startsWith("13:15"), // Changed to match the actual start of the time range
    //     orElse: () {
    //       debugPrint("❌ No Day 2 EventItem starts with '13:15' in ${matchingItemDay2.stage1Events?.map((e) => e.time).toList()}");
    //       throw Exception("❌ No Day 2 EventItem starts with '13:15'");
    //     },
    //   );
    //
    //   debugPrint('🎬 Matching Day 2 Event: ${eventDay2.title} at ${eventDay2.time}');
    //
    //   // Fire 5 seconds from now for debug purposes
    //   final fireTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    //   final formatted = "${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}";
    //
    //   debugPrint("🔔 Scheduling debug notification for '${eventDay2.title}' at $formatted");
    //
    //   await _notifier.fln.zonedSchedule(
    //     9999,
    //     "🔔 Coming Up: ${eventDay2.title}",
    //     "Starting at 1:00 PM on April 27", // Updated the starting time in the notification body
    //     fireTime,
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         'events',
    //         'Event reminders',
    //         importance: Importance.max,
    //         priority: Priority.high,
    //         color: Color(0xFFEF5350),
    //         colorized: true,
    //       ),
    //       iOS: DarwinNotificationDetails(
    //         presentAlert: true,
    //         presentBadge: true,
    //         presentSound: true,
    //       ),
    //     ),
    //     uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //     matchDateTimeComponents: DateTimeComponents.dateAndTime,
    //   );
    //
    //   await _notifier.logPending("after debug schedule (simulated 1:15 PM)");
    //   return;
    // }

    final now = tz.TZDateTime.now(tz.getLocation('America/New_York'));
    // debugPrint('⏱ Current time: $now');

    final List<List<ScheduleItem>> allDaysSchedules = [
      scheduleService.day1ScheduleData,
      scheduleService.day2ScheduleData,
    ];

    final List<int> dayDates = [26, 27];

    for (int i = 0; i < allDaysSchedules.length; i++) {
      // debugPrint('🗓️ Processing Day ${i + 1} Schedule (${dayDates[i]}): ${allDaysSchedules[i].map((item) => item.time).toList()}');
      for (final item in allDaysSchedules[i]) {
        final events = [...?item.stage1Events, ...?item.stage2Events];
        // debugPrint('  ⏰ Processing time slot: ${item.time}, Events: ${events.map((e) => "${e.title} (${e.time})").toList()}');
        for (final e in events) {
          // debugPrint('    🔍 Processing event: ${e.title} at ${e.time}');
          // Skip if time is invalid or title is blank
          if (!e.time.contains('-') || e.performanceName.trim().isEmpty) {
            // debugPrint('      ➡️ Skipping due to invalid time or empty title.');
            continue;
          }

          // Skip known filler or sponsor-related events
          final lowerTitle = e.performanceName.toLowerCase();
          if (lowerTitle.contains('sponsor') ||
              lowerTitle.contains('raffle') ||
              lowerTitle.contains('advertising') ||
              lowerTitle.contains('individual') ||
              lowerTitle.contains('organizer') ||
              lowerTitle.contains('downtown') ||
              lowerTitle.contains('placeholder')) {
            // debugPrint('      ➡️ Skipping due to filler/sponsor keyword.');
            continue;
          }

          final startStr = e.time.split('-')[0].trim();
          final parts = startStr.split(':');
          if (parts.length != 2) {
            // debugPrint('      ➡️ Skipping due to invalid time format: $startStr');
            continue;
          }

          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) {
            // debugPrint('      ➡️ Skipping due to invalid hour or minute: $startStr');
            continue;
          }

          // Target time of the event in Boston timezone
          final eventStartBoston = tz.TZDateTime(
            tz.getLocation('America/New_York'),
            2025,
            4,
            dayDates[i],
            hour,
            minute,
          );
          // debugPrint('      🎯 Event start time (Boston): $eventStartBoston (Day ${i + 1})');

          // Lead time is 15 minutes before the event
          final leadTime = const Duration(minutes: 15);
          final fireTimeBoston = eventStartBoston.subtract(leadTime);
          // debugPrint('      🔔 Notification fire time (Boston): $fireTimeBoston');

          // 🔔 Schedule only if current time in Boston is *exactly* 15 minutes before the event time in Boston
          if (now.year == fireTimeBoston.year &&
              now.month == fireTimeBoston.month &&
              now.day == fireTimeBoston.day &&
              now.hour == fireTimeBoston.hour &&
              now.minute == fireTimeBoston.minute) {
            try {
              await _notifier.schedule(
                id: id++,
                title: '🔔 Coming up: ${e.performanceName}',
                body: 'Starting at ${startStr}',
                when: eventStartBoston,
                leadTime: leadTime,
              );
              // debugPrint(
              //   '✅ Scheduled notification for ${e.title} at $eventStartBoston',
              // );
            } catch (e) {
              // debugPrint('❌ Failed to schedule notification: $e');
            }
          } else {
            // debugPrint('      ➡️ Not scheduling. Current time ($now) is not 15 minutes before event time ($eventStartBoston).');
          }
        }
      }
    }

    // Verify scheduled notifications
    await _notifier.logPending('after scheduling only matching events');
  }
}
