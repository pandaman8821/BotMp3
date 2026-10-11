package com.botmp3.app

import android.app.AlarmManager
import android.os.Build
import android.os.PowerManager
import android.content.ContentUris
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.util.Size
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Actividad principal de BotMp3.
 *
 * Extiende [AudioServiceActivity] (requisito de `audio_service` /
 * `just_audio_background`) y expone un puente con **MediaStore** para que la app
 * importe automáticamente toda la música del dispositivo, sin que el usuario
 * tenga que elegir archivos a mano:
 *
 *  - `queryAudio`  -> lista de pistas (título, artista, álbum, año, duración, ruta/URI)
 *  - `albumArt`    -> extrae la carátula del álbum a un JPG en la caché y devuelve la ruta
 */
class MainActivity : AudioServiceActivity() {

    private val channelName = "botmp3/media"
    private val notificationChannelName = "botmp3/notifications"
    private val appInfoChannelName = "botmp3/appinfo"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queryAudio" -> runCatching { queryAudio() }
                        .onSuccess { result.success(it) }
                        .onFailure { result.error("query_failed", it.message, null) }

                    "albumArt" -> {
                        val albumId = (call.argument<Number>("albumId") ?: -1).toLong()
                        runCatching { albumArt(albumId) }
                            .onSuccess { result.success(it) }
                            .onFailure { result.error("art_failed", it.message, null) }
                    }

                    "albumArtForTrack" -> {
                        val trackId = (call.argument<Number>("trackId") ?: -1).toLong()
                        runCatching { albumArtForTrack(trackId) }
                            .onSuccess { result.success(it) }
                            .onFailure { result.error("art_failed", it.message, null) }
                    }

                    else -> result.notImplemented()
                }
            }

        // -------- Notificaciones propias (tendencias musicales) --------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val id = (call.argument<Number>("id") ?: 1001).toInt()
                        val title = call.argument<String>("title") ?: "BotMp3"
                        val body = call.argument<String>("body") ?: ""
                        val channelId =
                            call.argument<String>("channelId") ?: NotificationHelper.CHANNEL_ID
                        val channelName =
                            call.argument<String>("channelName") ?: NotificationHelper.CHANNEL_NAME
                        NotificationHelper.show(this, id, title, body, channelId, channelName)
                        result.success(true)
                    }

                    "scheduleDaily" -> {
                        val hour = (call.argument<Number>("hour") ?: 20).toInt()
                        val minute = (call.argument<Number>("minute") ?: 0).toInt()
                        val proxima = java.util.Calendar.getInstance().apply {
                            add(java.util.Calendar.DAY_OF_YEAR, 1)
                            set(java.util.Calendar.HOUR_OF_DAY, hour)
                            set(java.util.Calendar.MINUTE, minute)
                            set(java.util.Calendar.SECOND, 0)
                        }
                        TrendsReminderReceiver.programar(
                            this,
                            AlarmManager.INTERVAL_DAY,
                            proxima.timeInMillis,
                        )
                        result.success(true)
                    }

                    "notificationsEnabled" -> {
                        val manager =
                            getSystemService(android.app.NotificationManager::class.java)
                        result.success(manager?.areNotificationsEnabled() ?: true)
                    }

                    "ignoringBatteryOptimizations" -> {
                        val power = getSystemService(PowerManager::class.java)
                        val libre = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            power?.isIgnoringBatteryOptimizations(packageName) ?: false
                        } else {
                            true
                        }
                        result.success(libre)
                    }

                    "cancelReminder" -> {
                        TrendsReminderReceiver.cancelar(this)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // -------- Versión real del APK instalado --------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appInfoChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "version" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        @Suppress("DEPRECATION")
                        val codigo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            info.versionCode.toLong()
                        }
                        result.success(
                            mapOf(
                                "name" to (info.versionName ?: ""),
                                "code" to codigo,
                            ),
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** Devuelve todas las pistas musicales que MediaStore conoce. */
    private fun queryAudio(): List<Map<String, Any?>> {
        val tracks = mutableListOf<Map<String, Any?>>()
        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.DATA,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.ARTIST} COLLATE NOCASE ASC, " +
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"

        contentResolver.query(collection, projection, selection, null, sortOrder)?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getLong(0)
                tracks.add(
                    mapOf(
                        "id" to id,
                        "title" to cursor.getString(1),
                        "artist" to cursor.getString(2),
                        "album" to cursor.getString(3),
                        "albumId" to cursor.getLong(4),
                        "year" to cursor.getInt(5),
                        "durationMs" to cursor.getLong(6),
                        "sizeBytes" to cursor.getLong(7),
                        "mimeType" to cursor.getString(8),
                        "path" to cursor.getString(9),
                        "uri" to ContentUris.withAppendedId(collection, id).toString(),
                    ),
                )
            }
        }
        return tracks
    }

    /**
     * Resuelve el álbum de una pista concreta de MediaStore y devuelve su carátula.
     * Se usa desde el editor cuando la canción proviene de la biblioteca del sistema.
     */
    private fun albumArtForTrack(trackId: Long): String? {
        if (trackId <= 0) return null
        val albumId = runCatching {
            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Audio.Media.ALBUM_ID),
                "${MediaStore.Audio.Media._ID} = ?",
                arrayOf(trackId.toString()),
                null,
            )?.use { cursor -> if (cursor.moveToFirst()) cursor.getLong(0) else -1L }
        }.getOrNull() ?: -1L
        return albumArt(albumId)
    }

    /**
     * Extrae la carátula del álbum como JPG en la caché de la app y devuelve su ruta.
     * Devuelve null si ese álbum no tiene imagen.
     */
    private fun albumArt(albumId: Long): String? {
        if (albumId <= 0) return null
        val directory = File(cacheDir, "albumart").apply { mkdirs() }
        val target = File(directory, "$albumId.jpg")
        if (target.exists() && target.length() > 0) return target.absolutePath

        val bitmap: Bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            runCatching {
                val uri = ContentUris.withAppendedId(
                    MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                    albumId,
                )
                contentResolver.loadThumbnail(uri, Size(600, 600), null)
            }.getOrNull()
        } else {
            // Android 7-9: se lee la ruta de la carátula que expone MediaStore.
            val artPath = runCatching {
                contentResolver.query(
                    ContentUris.withAppendedId(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI, albumId),
                    arrayOf(MediaStore.Audio.Albums.ALBUM_ART),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else null
                }
            }.getOrNull()
            if (artPath != null) runCatching { android.graphics.BitmapFactory.decodeFile(artPath) }
                .getOrNull() else null
        } ?: return null

        return runCatching {
            FileOutputStream(target).use { output ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 88, output)
            }
            bitmap.recycle()
            target.absolutePath
        }.getOrNull()
    }
}
