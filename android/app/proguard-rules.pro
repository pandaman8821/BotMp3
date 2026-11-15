# Reglas ProGuard/R8 de BotMp3
# (solo se aplican si activas minifyEnabled en build.gradle)

# Servicio de audio en segundo plano (just_audio_background / audio_service)
-keep class com.ryanheise.** { *; }

# Codigo nativo propio: widgets, receptores y canales con Flutter
-keep class com.botmp3.app.** { *; }
-keep class com.example.botmp3.** { *; }

# Avisos habituales de Flutter y flutter_secure_storage con R8
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
