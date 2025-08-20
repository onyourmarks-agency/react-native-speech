package com.speech

import android.content.Context
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import com.facebook.react.bridge.ReactApplicationContext

class AudioDuckingModule(reactContext: ReactApplicationContext) {
    private var audioFocusRequest: AudioFocusRequest? = null

    private val audioManager: AudioManager by lazy {
        reactContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    fun startDucking() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest
                .Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(
                  android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                )
                .setWillPauseWhenDucked(false)
                .setAcceptsDelayedFocusGain(false)
                .build()

            audioFocusRequest?.let {
                val result = audioManager.requestAudioFocus(it)
                android.util.Log.d("AudioDucking", "Audio focus request result: $result")
            }
            return
        }

        val result = audioManager.requestAudioFocus(
            {},
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
        )

        android.util.Log.d("AudioDucking", "Audio focus request result (legacy): $result")
    }

    fun stopDucking() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager.abandonAudioFocusRequest(it)
            }
            return
        }

        audioManager.abandonAudioFocus({})
    }
}
