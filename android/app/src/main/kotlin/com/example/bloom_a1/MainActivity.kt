package com.example.bloom_a1

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.example.bloom_a1/alarm"

  override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)

      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
          if (call.method == "scheduleAlarm") {
              val timeMillis = call.argument<Long>("time") ?: return@setMethodCallHandler
              val message = call.argument<String>("message") ?: "Default TTS message" // <-- get message from flutter!

              scheduleAlarm(timeMillis, message)
              result.success(null)
          }
      }
  }

  private fun scheduleAlarm(timeMillis: Long, message: String) {
      val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
      val intent = Intent(this, AlarmReceiver::class.java).apply {
          putExtra("message", message) // <-- PASS the message here!
      }
      val pendingIntent = PendingIntent.getBroadcast(
          this,
          0,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      )

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
      } else {
          alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
      }
  }
}

