# Reglas ProGuard/R8 de BotMp3
# Plugins con llamadas nativas (FFI) que deben conservarse.
-keep class com.erikas.audiotags.** { *; }
-keep class com.ryanheise.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Voz
-keep class android.speech.** { *; }

# Modelo de datos serializado a JSON
-keep class com.botmp3.app.** { *; }

-dontwarn org.jetbrains.annotations.**
