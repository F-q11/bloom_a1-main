import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/ScheduledNotification.dart';
import '../multi_use_classes.dart';
import '../screens/watering_schedule_screen.dart';

class NotificationService extends GetxService{
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  late Box<ScheduledNotification> _notificationBox;


  //Initialize
  Future<NotificationService> init() async {
    if (_isInitialized) return this; //prevent reinitialization

// Initialize Hive box
    _notificationBox = Hive.box<ScheduledNotification>('notifications');
    //init timezone handling
    tz.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    //request permission
    final permissionStatus = await notificationPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    if (permissionStatus == null || permissionStatus == false) {
      return this;
    }

    //prepare android init settings
    const initSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    //prepare ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    //prepare init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    //initialize the plugin
    await notificationPlugin.initialize(initSettings
    ,onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationClicked(response);
      },
    );
    _isInitialized = true;
    return this;
  }

  void _onNotificationClicked(NotificationResponse response) {
    // Handle notification click
    print("Onclick");
    final notification = _notificationBox.get(response.id);
    if (notification != null) {
      // Speak the notification content
      MultiUseClasses.ttsServices.speak(
          "${notification.title}. ${notification.body}"
      );

      // You can add additional actions here:
      // - Navigate to specific screen
      // - Perform specific action
      // - Show dialog

      // Example: Navigate to watering schedule screen
      Get.to(() => WateringScheduleScreen());

      // Remove the notification from storage
      _notificationBox.delete(response.id);
    }
  }
  //Notifications Details Setup
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_channel_id",
        "Daily Notifications",
        channelDescription: "Daily Notifications Channel",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }


  Future<void> scheduleNotification({
    int id = 1,
    String? title,
    String? body,
    required DateTime scheduledTime,
  }) async {
    // Save to local storage
    final notification = ScheduledNotification(
      id: id,
      title: title!,
      body: body!,
      scheduledTime: scheduledTime,
    );
    await _notificationBox.put(id, notification);

    //get current date and time
    final now = tz.TZDateTime.now(tz.local);


    //schedule the notification
    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails(),
    
      //Android specific: Allow notification while device is in low-power mode
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      //make the notification repeat daily at the same time
      matchDateTimeComponents: DateTimeComponents.time,
      payload: id.toString(), // Important for identification
    );
  }



  //Cancel All Notification
  Future<void> cancelAllNotification() async {
    await notificationPlugin.cancelAll();
  }

}
