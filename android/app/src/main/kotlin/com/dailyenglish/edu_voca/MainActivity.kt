package com.dailyenglish.edu_voca

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var track: AudioTrack? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Model files must be real paths for the native TTS engine; PCM from it
        // is played here so no extra audio plugin is needed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "edu_voca/speech_audio")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "filesDir" -> result.success(filesDir.absolutePath)
                        "play" -> {
                            play(call.argument<FloatArray>("samples")!!,
                                call.argument<Int>("sampleRate")!!)
                            result.success(null)
                        }
                        "stop" -> {
                            stop()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("audio", e.message, null)
                }
            }
    }

    private fun play(samples: FloatArray, sampleRate: Int) {
        stop()
        if (samples.isEmpty()) return
        val created = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build())
            .setAudioFormat(AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .build())
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(samples.size * 4)
            .build()
        try {
            created.write(samples, 0, samples.size, AudioTrack.WRITE_BLOCKING)
            created.play()
        } catch (e: Exception) {
            created.release()
            throw e
        }
        track = created
    }

    private fun stop() {
        track?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        track = null
    }

    override fun onDestroy() {
        stop()
        super.onDestroy()
    }
}
