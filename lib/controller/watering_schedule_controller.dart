import 'package:get/get.dart';
import '../models/watering_schedule_table.dart';
import '../services/db_helper.dart';
import 'package:bloom_a1/multi_use_classes.dart';

class WateringScheduleController extends GetxController {
  final DBHelper _dbHelper = DBHelper();

  final isLoading = false.obs;
  // Reactive list to hold schedules
  var wateringSchedules = <WateringScheduleTable>[].obs;

  // Load watering schedules for a specific plant
  Future<void> loadSchedules(int plantId) async {
    isLoading.value = true;
    final schedules = await _dbHelper.getWateringScheduleByPlant(plantId);
    wateringSchedules.assignAll(schedules);
    isLoading.value = false;
  }

  // Add new schedule
  Future<void> addSchedule(WateringScheduleTable schedule) async {
    await _dbHelper.insertWateringSchedule(schedule);
    await loadSchedules(schedule.plantId);
  }

  // Update schedule
  Future<void> updateSchedule(WateringScheduleTable schedule) async {
    await _dbHelper.updateWateringSchedule(schedule);
    await loadSchedules(schedule.plantId);
  }

  // Delete schedule
  Future<void> deleteSchedule(int plantId) async {
    await _dbHelper.deleteSchedule(plantId);
    await loadSchedules(plantId);
    // Cancel all notifications for this plant
    await MultiUseClasses.notificationServices.cancelAllNotification();
  }
}