import 'package:bloom_a1/services/notification_service.dart';
import 'package:bloom_a1/services/tts_service.dart';
import 'package:get/get.dart';

class MultiUseClasses {

  static final notificationServices = Get.find<NotificationService>();
  static final ttsServices = Get.find<TtsService>();

}