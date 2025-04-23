import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ScheduledNotification {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String body;
  @HiveField(3)
  final DateTime scheduledTime;
  @HiveField(4)
  final String? action; // Optional: Add action type if needed

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.action,
  });
}