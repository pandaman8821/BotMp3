package com.botmp3.app

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Detecta cuando se conecta o desconecta un dispositivo de audio
 * (auriculares con cable, Bluetooth, AUX/USB) y avisa a Flutter.
 *
 * No necesita permisos: usa AudioDeviceCallback (API 23+).
 */
object AudioDeviceWatcher {
    private var registrado = false
    private var callback: AudioDeviceCallback? = null

    fun iniciar(context: Context, canal: MethodChannel) {
        if (registrado) return
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val cb = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                if (addedDevices.isNullOrEmpty()) return
                canal.invokeMethod("conectado", null)
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                if (removedDevices.isNullOrEmpty()) return
                canal.invokeMethod("desconectado", null)
            }
        }
        audio.registerAudioDeviceCallback(cb, Handler(Looper.getMainLooper()))
        callback = cb
        registrado = true
    }

    fun detener(context: Context) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        callback?.let { audio.unregisterAudioDeviceCallback(it) }
        callback = null
        registrado = false
    }
}