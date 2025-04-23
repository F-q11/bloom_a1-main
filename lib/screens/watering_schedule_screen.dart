import 'package:bloom_a1/controller/plant_controller.dart';
import 'package:bloom_a1/multi_use_classes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../controller/watering_schedule_controller.dart';
import '../models/watering_schedule_table.dart';
import 'home_screen.dart';

class WateringScheduleScreen extends StatefulWidget {
  const WateringScheduleScreen({super.key});

  @override
  State<WateringScheduleScreen> createState() => _WateringScheduleScreenState();
}

class _WateringScheduleScreenState extends State<WateringScheduleScreen> {
  final PlantController _plantController = Get.find();
  final WateringScheduleController _sController =
  Get.put(WateringScheduleController());

  int _selectedPlantIndex = 0;
  List<String> _plantNames = [];

  Map<String, DateTime> lastWatered = {};
  Map<String, List<DateTime>> wateringSchedule = {};

  @override
  void initState() {
    super.initState();
    // Initialize TTS and Notification services
    MultiUseClasses.ttsServices.init();
    MultiUseClasses.notificationServices.init();
  }

  void _setLastWatered(DateTime date) {
    String plant = _plantNames[_selectedPlantIndex];
    setState(() {
      lastWatered[plant] = date;
      _generateWateringSchedule(plant);
    });
  }

  Future<void> _generateWateringSchedule(String plant) async {
    final plantSchedule = _plantController.plants[_selectedPlantIndex];
    DateTime startDate = lastWatered[plant] ?? DateTime.now();
    List<DateTime> schedule = [];
    int waterDay = 0;

    //get number of watering based the current season
    if (_plantController.currentSeason.value == "الشتاء") {
      waterDay = (30 / double.parse(plantSchedule.winter)).round();
    }
    if (_plantController.currentSeason.value == "الصيف") {
      waterDay = (30 / double.parse(plantSchedule.summer)).round();
    }

    for (int i = 1; i <= 30; i += waterDay) {
      schedule.add(startDate.add(Duration(days: i)));
    }
    wateringSchedule[plant] = schedule;

    //update or insert to watering_schedule table
    if (_sController.wateringSchedules.isNotEmpty) {
      await _sController.deleteSchedule(plantSchedule.id!);
    }

    for (int i = 0; i < schedule.length; i++) {
      await _sController.addSchedule(WateringScheduleTable(
        plantId: plantSchedule.id!,
        frequency: waterDay.toString(),
        day: schedule[i].day.toString(),
      ));

      // Schedule notification for each watering day
      await _scheduleWateringNotification(
        plantName: plant,
        date: schedule[i],
      );
    }
  }

  Future<void> _scheduleWateringNotification({
    required String plantName,
    required DateTime date,
  }) async {
    final notificationId = date.hashCode; // Unique ID based on date

    await MultiUseClasses.notificationServices.scheduleNotification(
      id: notificationId,
      title: "موعد ري النبات",
      body: "حان وقت ري نبات $plantName اليوم",
      scheduledTime: DateTime.now().add(Duration(seconds: 5)), // Test after 10 seconds
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_plantController.plants.isEmpty) {
      _plantController.loadPlants();
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFA9A9A9), // الرمادي الفاتح
            Color(0xFF577363), // الأخضر الباهت
            Color(0xFF063D1D), // الأخضر الغامق
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF063D1D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF204D32)),
            onPressed: () {
              Get.offAll(() => HomeScreen());
            },
          ),
          title: Center(
            child: Text(
              "جدول الري",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF063D1D),
              ),
            ),
          ),
        ),
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3C1E),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_circle, size: 80, color: Colors.white),
                    SizedBox(height: 10),
                    Text("مرحبًا بك",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("مشاركة رابط الحساب"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("تسجيل خروج"),
                onTap: () {
                  AuthController auth = Get.find();
                  auth.logout();
                },
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (_plantController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_plantController.plants.isEmpty) {
              return const Center(child: Text("لا يوجد نباتات بعد"));
            }
            _plantNames = _plantController.plants.map((plant) {
              return plant.name;
            }).toList();
            _sController.loadSchedules(
                _plantController.plants[_selectedPlantIndex].id!);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // optional: to maintain RTL feel
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: List.generate(_plantNames.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPlantIndex == index
                                  ? const Color(0xFF204D32)
                                  : const Color(0xFFDCE3C6),
                              foregroundColor: _selectedPlantIndex == index
                                  ? Colors.white
                                  : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedPlantIndex = index;
                              });
                            },
                            child: Text(
                              _plantNames[index],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF204D32), // استخدام اللون المطلوب
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime(2025, 12, 31),
                    );
                    if (pickedDate != null) {
                      _setLastWatered(pickedDate);
                    }
                  },
                  child: const Text("تحديد آخر يوم ري"),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: _buildCalendar(),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    List<String> daysOfWeek = [
      "السبت",
      "الأحد",
      "الاثنين",
      "الثلاثاء",
      "الأربعاء",
      "الخميس",
      "الجمعة",
    ];
    List<int> daysInMonth = List.generate(30, (index) => index + 1);
    String plantName = _plantNames[_selectedPlantIndex];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: daysOfWeek.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Obx(() {
            if (_sController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final schedules = _sController.wateringSchedules;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: daysInMonth.length,
                itemBuilder: (context, index) {
                  final day = daysInMonth[index];
                  final isWateringDay =
                  schedules.any((s) => int.tryParse(s.day) == day);

                  return Container(
                    decoration: BoxDecoration(
                      color: isWateringDay
                          ? const Color(0xFF204D32)
                          : const Color(0xFFDCE3C6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isWateringDay ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}