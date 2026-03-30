// lib/services/notification_service.dart
import 'dart:io';
import 'dart:ui'; // for Color
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  /// public so you can call pendingNotificationRequests() in debug
  final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

  /* ─────────────  static details reused by every schedule() call  ─────────── */
  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'events',
      'Event reminders',
      importance: Importance.high,
      priority: Priority.high,
      channelShowBadge: true,
      color: Color(0xFFEF5350), // vivid red header
      colorized: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  Future<void> logPending(String tag) async {
    final list = await fln.pendingNotificationRequests();
    debugPrint('[$tag] pending=${list.length}');
    for (final r in list) {
      debugPrint('  • id=${r.id}  title=${r.title}');
    }
  }

  /* ─────────────────── init ─────────────────── */
  Future<void> init() async {
    /* 0. Time‑zone */
    tz.initializeTimeZones();
    // Set local timezone using timezone package without flutter_native_timezone
    try {
      // Default to device's timezone
      tz.setLocalLocation(tz.local);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    /* 1. Android channel */
    const channel = AndroidNotificationChannel(
      'events',
      'Event reminders',
      description: 'Alerts 10 min before festival events',
      importance: Importance.high,
    );
    await fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    /* 2. Initialise plugin + iOS permissions */
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await fln
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    /* 3. Android 13+ POST_NOTIFICATIONS runtime permission */
    if (Platform.isAndroid) {
      await fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> requestPermissions() async {
    await fln
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /* ─────────────────── schedule ─────────────────── */
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
    String body = '',
    Duration leadTime = const Duration(minutes: 10),
  }) async {
    final fireTime = tz.TZDateTime.from(when, tz.local).subtract(leadTime);
    if (fireTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await fln.zonedSchedule(
      id,
      title,
      body,
      fireTime,
      _notifDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /* ─────────────────── cancel helpers ─────────────────── */
  Future<void> cancelAll() => fln.cancelAll();
}
