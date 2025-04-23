import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';


class TtsService extends GetxService{
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<TtsService> init() async {
    if (_isInitialized) return this;

    // Android audio configuration
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers
      ],
    );

    // Language configuration
    final languages = await _tts.getLanguages;
    if (languages.contains('ar-SA')) {
      await _tts.setLanguage('ar-SA');
    } else if (languages.contains('ar')) {
      await _tts.setLanguage('ar');
    }

    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _isInitialized = true;
    return this;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _tts.speak(text);
  }
}