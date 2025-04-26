package com.example.bloom_a1;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.speech.tts.TextToSpeech;
import java.util.Locale;

public class AlarmReceiver extends BroadcastReceiver {

    private TextToSpeech tts;

    @Override
    public void onReceive(Context context, Intent intent) {
        // Get message from Intent extras
        final String messageToSpeak = intent.getStringExtra("message"); // <-- make it final

        // Initialize TextToSpeech
        tts = new TextToSpeech(context.getApplicationContext(), status -> {
            if (status == TextToSpeech.SUCCESS) {
                tts.setLanguage(Locale.US);
                tts.setSpeechRate(1.0f);

                // Use the final variable inside the lambda
                String text = (messageToSpeak == null || messageToSpeak.isEmpty())
                        ? "Default TTS message"
                        : messageToSpeak;

                tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "TTS_ID");
            }
        });
    }
}
