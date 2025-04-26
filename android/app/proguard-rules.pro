# Preserve TensorFlow Lite classes for reflection
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.experimental.** { *; }
-dontwarn org.tensorflow.**
-dontwarn org.tensorflow.lite.**
