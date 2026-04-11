# ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Language-specific recognizers (missing if only using default Latin)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter ML Kit plugin
-keep class com.google_mlkit_text_recognition.** { *; }