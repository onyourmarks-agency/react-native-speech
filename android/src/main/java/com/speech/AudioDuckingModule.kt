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
                .setWillPauseWhenDucked(false)
                .build()

            audioFocusRequest?.let {
                audioManager.requestAudioFocus(it)
            }
            return
        }

        audioManager.requestAudioFocus(
            {},
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
        )
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
