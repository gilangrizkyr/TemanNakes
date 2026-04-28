# AdMob ProGuard rules
-keep public class com.google.android.gms.ads.** {
   public *;
}

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Connectivity Plus
-keep class com.baseflow.connectivity.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }
