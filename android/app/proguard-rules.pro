# Flutter Wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Hive and Secure Storage rules
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.hivedb.** { *; }
-dontwarn io.hivedb.**
