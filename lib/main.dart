import 'package:bloom_a1/services/ScheduledNotificationAdapter.dart';
import 'package:bloom_a1/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/ScheduledNotification.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initialServices();
  runApp(const MyApp());
}


Future<void> initialServices() async {
  // Initialize Hive
  await Hive.initFlutter();
  // Register adapters
  Hive.registerAdapter(ScheduledNotificationAdapter());
  // Open boxes
  await Hive.openBox<ScheduledNotification>('notifications');

  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => TtsService().init());
  }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bloom Assist',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}
