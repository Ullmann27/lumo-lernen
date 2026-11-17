package dev.ullmann.lumo

import java.util.concurrent.CancellationException
import kotlin.math.sqrt

/** A bounded RMS envelope from the actual local PCM bytes.
 * This controls the closed muzzle's amplitude; it is not a phoneme/viseme map.
 * Parse once off the main thread. Sampling is allocation-free and uses the
 * MediaPlayer's media position, including its actual playback-rate changes. */
class LumoSpeechEnvelope private constructor(
    private val amplitudes: FloatArray,
    val durationMs: Int,
    val sampleRate: Int,
    val channels: Int,
) {
    val available: Boolean get() = amplitudes.isNotEmpty()

    fun amplitudeAt(positionMs: Int): Double {
        if (positionMs < 0 || positionMs >= durationMs || amplitudes.isEmpty()) return 0.0
        return amplitudes[(positionMs / WINDOW_MS).coerceAtMost(amplitudes.lastIndex)].toDouble()
    }

    companion object {
        const val WINDOW_MS = 20
        private const val MAX_BYTES = 3 * 1024 * 1024
        private const val MAX_SECONDS = 30
        val EMPTY = LumoSpeechEnvelope(FloatArray(0), 0, 0, 0)

        fun fromWave(bytes: ByteArray): LumoSpeechEnvelope {
            if (bytes.size < 44 || bytes.size > MAX_BYTES) return EMPTY
            fun tag(at: Int, value: String): Boolean = at >= 0 && at + 4 <= bytes.size &&
                (0..3).all { bytes[at + it].toInt() and 255 == value[it].code }
            fun u16(at: Int): Int = (bytes[at].toInt() and 255) or
                ((bytes[at + 1].toInt() and 255) shl 8)
            fun u32(at: Int): Long = u16(at).toLong() or (u16(at + 2).toLong() shl 16)
            if (!tag(0, "RIFF") || !tag(8, "WAVE") || u32(4) + 8 != bytes.size.toLong()) return EMPTY
            var rate = 0; var channelCount = 0; var alignment = 0
            var dataStart = -1; var dataBytes = 0; var cursor = 12; var chunks = 0
            while (cursor + 8 <= bytes.size) {
                if (Thread.currentThread().isInterrupted) throw CancellationException("Envelope cancelled")
                if (++chunks > 512) return EMPTY
                val size = u32(cursor + 4)
                val start = cursor + 8
                val end = start.toLong() + size
                if (size > Int.MAX_VALUE || end > bytes.size || end < start) return EMPTY
                when {
                    tag(cursor, "fmt ") -> {
                        if (rate != 0 || size < 16 || u16(start) != 1 || u16(start + 14) != 16) return EMPTY
                        channelCount = u16(start + 2)
                        val sampleRate = u32(start + 4)
                        if (channelCount !in 1..2 || sampleRate !in 8000..48000) return EMPTY
                        rate = sampleRate.toInt(); alignment = u16(start + 12)
                        if (alignment != channelCount * 2 || u32(start + 8) != rate.toLong() * alignment) return EMPTY
                    }
                    tag(cursor, "data") -> {
                        if (dataStart >= 0 || size == 0L) return EMPTY
                        dataStart = start; dataBytes = size.toInt()
                    }
                }
                cursor = (end + (size and 1)).toInt()
                if (cursor > bytes.size) return EMPTY
            }
            if (cursor != bytes.size || rate == 0 || dataStart < 0 || dataBytes % alignment != 0) return EMPTY
            val frames = dataBytes / alignment
            if (frames < 1 || frames > rate * MAX_SECONDS) return EMPTY
            val windowFrames = rate * WINDOW_MS / 1000
            val windows = (frames + windowFrames - 1) / windowFrames
            val result = FloatArray(windows)
            for (window in result.indices) {
                if (Thread.currentThread().isInterrupted) throw CancellationException("Envelope cancelled")
                val first = window * windowFrames
                val last = minOf(frames, first + windowFrames)
                var squared = 0.0
                for (frame in first until last) {
                    for (channel in 0 until channelCount) {
                        val at = dataStart + frame * alignment + channel * 2
                        val signed = u16(at).toShort().toInt()
                        val sample = signed / 32768.0
                        squared += sample * sample
                    }
                }
                val rms = sqrt(squared / ((last - first) * channelCount))
                // Fixed, documented art gain; silence never creates motion.
                result[window] = ((rms - 0.006) / 0.24).coerceIn(0.0, 1.0).toFloat()
            }
            return LumoSpeechEnvelope(result, ((frames.toLong() * 1000 + rate - 1) / rate).toInt(), rate, channelCount)
        }
    }
}
