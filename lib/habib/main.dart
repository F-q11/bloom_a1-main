import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permission (Android 13+)
  await _requestNotificationPermission();

  // Initialize time zones
  tz.initializeTimeZones();
  final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(currentTimeZone));

  // Initialize notification & background services
  await NotificationService.init();

  runApp(const MyApp());
}

/// Request permission for notifications (Android 13+)
Future<void> _requestNotificationPermission() async {
  final notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    await Permission.notification.request();
  }

  final alarmStatus = await Permission.scheduleExactAlarm.status;
  if (!alarmStatus.isGranted) {
    await Permission.scheduleExactAlarm.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification TTS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _secondsController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _secondsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _scheduleNotification() async {
    try {
      final int delaySeconds = int.tryParse(_secondsController.text.trim()) ?? 0;
      final String message = _messageController.text.trim();

      if (delaySeconds <= 0 || message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid seconds and message')),
        );
        return;
      }

      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));


      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // unique id
        title: 'Scheduled Reminder',
        body: message,
        scheduledDate: scheduledDate,
      );

await NotificationService.scheduleAndroidAlarm(scheduledDate, message);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification scheduled!')),
      );
    } catch (e) {
      print('Error scheduling notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification + TTS')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _secondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter seconds delay',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Enter message to speak',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('Schedule Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
