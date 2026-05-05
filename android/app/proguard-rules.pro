# Flutter Proguard Rules
# Ini memberitahu R8 agar mengabaikan peringatan tentang library Google Play Core
# yang tidak ditemukan, karena aplikasi kita tidak menggunakan fitur Split Install.

-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Pertahankan kelas-kelas Flutter agar tidak dihapus saat optimasi
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
