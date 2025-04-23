import 'package:hive/hive.dart';

import '../models/ScheduledNotification.dart';

class ScheduledNotificationAdapter extends TypeAdapter<ScheduledNotification> {
  @override
  final int typeId = 1;

  @override
  ScheduledNotification read(BinaryReader reader) {
    return ScheduledNotification(
      id: reader.read(),
      title: reader.read(),
      body: reader.read(),
      scheduledTime: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledNotification obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.body);
    writer.write(obj.scheduledTime);
  }
}