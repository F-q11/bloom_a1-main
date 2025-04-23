import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService extends GetxService{
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;


  //Initialize
  Future<NotificationService> init() async {
    if (_isInitialized) return this; //prevent reinitialization

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
    await notificationPlugin.initialize(initSettings);
    _isInitialized = true;
    return this;
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

  //Show Notification
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return await notificationPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
    );
  }

/*

  Schedule a Notification at specified time

  - hour (0-23)
  - minute (0-59)

*/

  Future<void> scheduleNotification({
    int id = 1,
    String? title,
    String? body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    //get current date and time
    final now = tz.TZDateTime.now(tz.local);

    //create a date/time for today at the specified hout/min
    var scheduleDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      day,
      hour,
      minute,
    );

    //schedule the notification
    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      _notificationDetails(),
      //Ios specific: Use exact time specified (vs relative time)
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      //Android specific: Allow notification while device is in low-power mode
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      //make the notification repeat daily at the same time
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  //Cancel All Notification
  Future<void> cancelAllNotification() async {
    await notificationPlugin.cancelAll();
  }

}
