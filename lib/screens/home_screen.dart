import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/notification_service.dart';
import 'my_plants_screen.dart';
import 'camera_screen.dart';
import 'watering_schedule_screen.dart';
import 'chatbot_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _recognizedText = "";
  String cityName = "جاري التحديد...";
  String temperature = "--";
  String weatherDescription = "--";
  String humidity = "--";
  String windSpeed = "--";
  bool _isLoading = false;
  String weatherIcon = "";
  bool _locationPermissionRequested = false;

  final String apiKey = "5636a30b4ad0c22d1c43b749606f1f4d";

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeechToText();
    _loadLocationPermissionStatus();

  }

  Future<void> _loadLocationPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationPermissionRequested =
          prefs.getBool('locationPermissionRequested') ?? false;
    });

    if (!_locationPermissionRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog();
      });
    }
  }

  Future<void> _saveLocationPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationPermissionRequested', true);
  }

  void _initializeSpeechToText() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) => debugPrint("Status: $status"),
      onError: (error) => debugPrint("Error: $error"),
    );

    if (!available) {
      _showSnackbar("التعرف على الكلام غير متاح!");
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      _showSnackbar("جاري الاستماع...");
      _speechToText.listen(
        localeId: "ar_SA",
        onResult: (result) {
          setState(() => _recognizedText = result.recognizedWords);
          if (result.finalResult) {
            _handleVoiceCommand(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _handleVoiceCommand(String command) {
    debugPrint("Recognized command: $command");
    command = command.trim().toLowerCase();
    bool commandRecognized = false;

    if (command.contains("نباتي") ||
        command.contains("نبتاتي") ||
        command.contains("نبات")) {
      _navigateToMyPlantsScreen();
      commandRecognized = true;
    } else if (command.contains("الكاميرا")) {
      _navigateToCameraScreen();
      commandRecognized = true;
    } else if (command.contains("جدول") ||
        command.contains("ري") ||
        command.contains("جدول الري") ||
        command.contains("جدولي") ||
        command.contains("التقويم")) {
      _navigateToWateringScheduleScreen();
      commandRecognized = true;
    } else if (command.contains("الصفحة الرئيسية") ||
        command.contains("الرئيسية") ||
        command.contains("صفحة") ||
        command.contains("رئيسية")) {
      _navigateToHomeScreen();
      commandRecognized = true;
    } else if (command.contains("مساعدة") ||
        command.contains("المساعدة") ||
        command.contains("ساعدني") ||
        command.contains("ذكاء اصطناعي") ||
        command.contains("شات") ||
        command.contains("مساعده") ||
        command.contains("شات بوت")) {
      _navigateToChatBotScreen();
      commandRecognized = true;
    } else if (command.contains("موقع") ||
        command.contains("الموقع") ||
        command.contains("مكان") ||
        command.contains("أين") ||
        command.contains("طقس")) {
      _showLocationDialog();
      commandRecognized = true;
    }

    if (!commandRecognized) {
      _showSnackbar("لم يتم التعرف على الأمر!");
    }

    _stopListening();
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _navigateToMyPlantsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyPlantsScreen()),
    );
  }

  void _navigateToCameraScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  void _navigateToWateringScheduleScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WateringScheduleScreen()),
    );
  }

  void _navigateToChatBotScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatBotScreen()),
    );
  }

  void _navigateToHomeScreen() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyPlantsScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WateringScheduleScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatBotScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showLocationDialog() {
    if (_locationPermissionRequested) {
      _fetchLocationData();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("هل ترغب في مشاركة موقعك الحالي؟"),
          content: Text("سنستخدم موقعك لعرض معلومات الطقس لمدينتك"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _saveLocationPermissionStatus();
                setState(() {
                  _locationPermissionRequested = true;
                });
                await _fetchLocationData();
              },
              child: Text("نعم"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveLocationPermissionStatus();
                setState(() {
                  _locationPermissionRequested = true;
                });
              },
              child: Text("لا"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchLocationData() async {
    setState(() => _isLoading = true);
    try {
      Position? position = await _determinePosition();
      if (position != null) {
        debugPrint(
            "موقع تم الحصول عليه: ${position.latitude}, ${position.longitude}");
        await _getCityName(position.latitude, position.longitude);
        await _fetchWeatherDataByCoordinates(
            position.latitude, position.longitude);
      }
    } catch (e) {
      setState(() {
        cityName = "خطأ في تحديد الموقع";
        temperature = "غير متاح";
        weatherDescription = "غير متاح";
        humidity = "غير متاح";
        windSpeed = "غير متاح";
      });
      _showSnackbar("خطأ في تحديد الموقع: ${e.toString()}");
      debugPrint("Error in _fetchLocationData: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar("خدمة الموقع غير مفعلة. يرجى تفعيل GPS من الإعدادات.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar("تم رفض إذن الموقع.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar("تم رفض الإذن نهائيًا. يرجى تمكينه من إعدادات الهاتف.");
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }

  Future<void> _getCityName(double lat, double lon) async {
    try {
      debugPrint("جاري البحث عن المدينة بالإحداثيات: $lat, $lon");
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1&accept-language=ar'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("بيانات الاستجابة: $data");

        String? city;
        if (data['address'] != null) {
          city = data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              data['address']['suburb'] ??
              data['address']['neighbourhood'] ??
              data['address']['county'] ??
              data['address']['state'] ??
              data['address']['country'] ??
              "موقع غير معروف";
        }

        setState(() {
          cityName = city ?? "موقع غير معروف";
        });

        debugPrint("تم تحديد المدينة: $cityName");
      } else {
        debugPrint("خطأ في استجابة API: ${response.statusCode}");
        setState(() => cityName = "تعذر تحديد المدينة");
      }
    } catch (e) {
      setState(() => cityName = "تعذر تحديد المدينة");
      debugPrint("Error getting city name: $e");
    }
  }

  Future<void> _fetchWeatherDataByCoordinates(double lat, double lon) async {
    try {
      debugPrint("جاري جلب بيانات الطقس للإحداثيات: $lat, $lon");
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("بيانات الطقس: $data");
        setState(() {
          temperature = "${data['main']['temp']?.toStringAsFixed(1) ?? '--'}°C";
          weatherDescription = data['weather'][0]['description'] ?? "--";
          humidity = "${data['main']['humidity']?.toString() ?? '--'}%";
          windSpeed = "${(data['wind']['speed'] ?? 0).toStringAsFixed(1)} م/ث";
          weatherIcon = data['weather'][0]['icon'] ?? "";
        });
        _showWeatherInfoDialog();
      } else {
        debugPrint("خطأ في استجابة API الطقس: ${response.statusCode}");
        _showSnackbar("تعذر جلب بيانات الطقس");
      }
    } catch (e) {
      debugPrint("Error fetching weather: $e");
      _showSnackbar("حدث خطأ أثناء جلب بيانات الطقس");
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    try {
      debugPrint("جاري جلب بيانات الطقس للمدينة: $city");
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=ar'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("بيانات الطقس: $data");
        setState(() {
          temperature = "${data['main']['temp']?.toStringAsFixed(1) ?? '--'}°C";
          weatherDescription = data['weather'][0]['description'] ?? "--";
          humidity = "${data['main']['humidity']?.toString() ?? '--'}%";
          windSpeed = "${(data['wind']['speed'] ?? 0).toStringAsFixed(1)} م/ث";
          weatherIcon = data['weather'][0]['icon'] ?? "";
        });
        _showWeatherInfoDialog();
      } else {
        debugPrint("خطأ في استجابة API الطقس: ${response.statusCode}");
        _showSnackbar("تعذر جلب بيانات الطقس");
      }
    } catch (e) {
      debugPrint("Error fetching weather: $e");
      _showSnackbar("حدث خطأ أثناء جلب بيانات الطقس");
    }
  }

  void _showWeatherInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("معلومات الطقس في $cityName"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (weatherIcon.isNotEmpty)
                  Center(
                    child: Image.network(
                      'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.cloud, size: 80);
                      },
                    ),
                  ),
                _buildWeatherInfoRow("درجة الحرارة", temperature),
                _buildWeatherInfoRow("حالة الطقس", weatherDescription),
                _buildWeatherInfoRow("الرطوبة", humidity),
                _buildWeatherInfoRow("سرعة الرياح", windSpeed),
                SizedBox(height: 10),
                Text(
                  "آخر تحديث: ${DateTime.now().toString().substring(0, 16)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  "الإحداثيات: يتم عرض معلومات الطقس لموقعك الدقيق",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إغلاق"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _fetchLocationData();
              },
              child: Text("تحديث"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFA9A9A9),
                    Color(0xFF577363),
                    Color(0xFF063D1D),
                  ],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: const SizedBox(),
                    title: const Text(
                      "الصفحة الرئيسية",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF063D1D),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF063D1D)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  color: const Color(0xFF577363),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const HomeScreen()),
                                          );
                                        },
                                        child: Container(
                                          width: 150,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF577363),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'تسجيل خروج',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                    centerTitle: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showLocationDialog();
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  temperature != "--" ? temperature : "الطقس",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          "مرحبًا",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF063D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainButton("اكتشف نبتتك", "assets/images/plant1.png"),
                  const SizedBox(height: 15),
                  _buildMainButton("ابحث عن نبتتك", "assets/images/plant2.png"),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "أدوات العناية :",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCareTools(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _startListening,
        backgroundColor: Color(0xFFCDD4BA),
        child: const Icon(Icons.mic, color: Colors.black),
      ),
    );
  }

  Widget _buildMainButton(String text, String imagePath) {
    return GestureDetector(
      onTap: () {
        if (text == "اكتشف نبتتك") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraScreen()),
          );
        } else if (text == "ابحث عن نبتتك") {
          _navigateToMyPlantsScreen();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF577363),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: Image.asset(
                  imagePath,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildToolButton("جدول الري", Icons.water_drop),
          _buildToolButton("معلومات الطقس", Icons.cloud),
        ],
      ),
    );
  }

  Widget _buildToolButton(String text, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (text == "جدول الري") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WateringScheduleScreen()),
          );
        } else if (text == "معلومات الطقس") {
          _showLocationDialog();
        }
      },
      child: Container(
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: const Color(0xFFB3BEA6),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFB3BEA6),
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(153, 0, 0, 0),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: Colors.black),
            activeIcon: Icon(Icons.home, color: Colors.black),
            label: 'الصفحة الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist_outlined, color: Colors.black),
            activeIcon: Icon(Icons.local_florist, color: Colors.black),
            label: 'نبتاتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined, color: Colors.black),
            activeIcon: Icon(Icons.camera_alt, color: Colors.black),
            label: 'الكاميرا',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.black),
            activeIcon: Icon(Icons.calendar_today, color: Colors.black),
            label: 'جدول الري',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/chat.png', width: 24, height: 24),
            label: 'مساعدة',
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon() {
    if (weatherIcon.isEmpty) {
      return SizedBox();
    }
    return Image.network(
      'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
      width: 100,
      height: 100,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.cloud, size: 80);
      },
    );
  }
}
