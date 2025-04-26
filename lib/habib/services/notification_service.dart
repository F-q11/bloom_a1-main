import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const platform = MethodChannel('com.example.bloom_a1/alarm');

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        //  _handleNotificationTap();
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'main_channel_id',
      'Main Channel',
      description: 'Used for important scheduled notifications.',
      importance: Importance.max,
    );

    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);

    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel_id',
          'Main Channel',
          channelDescription: 'Used for important scheduled notifications.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
     
      payload: body, // ✅ pass the message text as payload
    );
  }

  

  static Future<void> scheduleAndroidAlarm(
    DateTime datetime,
    String message,
  ) async {
    if (Platform.isAndroid) {
      final int alarmTimeMillis = datetime.millisecondsSinceEpoch;
      try {
        await platform.invokeMethod('scheduleAlarm', {
          'time': alarmTimeMillis,
          'message': message, // ✅ send message with time
        });
      } on PlatformException catch (e) {
        print("Failed to schedule alarm: '${e.message}'.");
      }
    }
  }
}
