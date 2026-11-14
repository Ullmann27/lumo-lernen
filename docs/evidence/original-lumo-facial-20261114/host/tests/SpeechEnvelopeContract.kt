package dev.ullmann.lumo

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CancellationException
import kotlin.math.abs

private var checks = 0
private fun verify(ok: Boolean, label: String) {
    checks++
    check(ok) { label }
}
private fun wave(rate: Int = 44100, channels: Int = 1, padding: Boolean = false): ByteArray {
    val frames = rate / 10
    val pcm = ByteBuffer.allocate(frames * channels * 2).order(ByteOrder.LITTLE_ENDIAN)
    for (i in 0 until frames) for (c in 0 until channels) {
        val value = if (i < rate / 50 || i >= rate * 3 / 50) 0 else 8192
        pcm.putShort(value.toShort())
    }
    val chunks = ByteArrayOutputStream()
    if (padding) { chunks.write("JUNK".toByteArray()); chunks.write(byteArrayOf(1,0,0,0,55,0)) }
    chunks.write("fmt ".toByteArray())
    chunks.write(ByteBuffer.allocate(20).order(ByteOrder.LITTLE_ENDIAN).putInt(16)
        .putShort(1).putShort(channels.toShort()).putInt(rate).putInt(rate * channels * 2)
        .putShort((channels * 2).toShort()).putShort(16).array())
    chunks.write("data".toByteArray())
    chunks.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(pcm.array().size).array())
    chunks.write(pcm.array())
    val out = ByteArrayOutputStream();out.write("RIFF".toByteArray())
    out.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(chunks.size()+4).array())
    out.write("WAVE".toByteArray());out.write(chunks.toByteArray());return out.toByteArray()
}
fun main(args: Array<String>) {
    val bytes = wave();val original = bytes.clone();val envelope = LumoSpeechEnvelope.fromWave(bytes)
    verify(envelope.available && envelope.sampleRate == 44100 && envelope.channels == 1, "Actual F2 header format accepted")
    verify(envelope.durationMs == 100, "Media duration derives from exact PCM frames")
    verify(envelope.amplitudeAt(0) == 0.0 && envelope.amplitudeAt(19) == 0.0, "True initial silence is closed")
    verify(envelope.amplitudeAt(20) > .99 && envelope.amplitudeAt(59) > .99, "Only actual nonzero PCM opens the jaw")
    verify(envelope.amplitudeAt(60) == 0.0 && envelope.amplitudeAt(99) == 0.0, "Silent tail does not invent motion")
    verify(envelope.amplitudeAt(-1) == 0.0 && envelope.amplitudeAt(100) == 0.0, "Negative/end positions are closed")
    verify(bytes.contentEquals(original), "Parsing does not alter playback bytes")
    verify(LumoSpeechEnvelope.fromWave(wave(padding=true)).amplitudeAt(20) == envelope.amplitudeAt(20), "Odd padded RIFF chunks are parsed correctly")
    verify(LumoSpeechEnvelope.fromWave(wave(channels=2)).amplitudeAt(20) == envelope.amplitudeAt(20), "Interleaved channels normalized correctly")
    for ((offset,value,label) in listOf(Triple(0,0,"RIFF magic"),Triple(4,0,"RIFF declared size"),Triple(20,3,"Float encoding"),Triple(22,3,"Channel count"),Triple(32,4,"Block alignment"),Triple(34,24,"Bit depth"),Triple(40,255,"Data length"))) {
        val bad=bytes.clone();bad[offset]=value.toByte();verify(!LumoSpeechEnvelope.fromWave(bad).available,"Malformed $label is fail-closed")
    }
    verify(!LumoSpeechEnvelope.fromWave(ByteArray(43)).available,"Short WAV is fail-closed")
    verify(!LumoSpeechEnvelope.fromWave(ByteArray(3*1024*1024+1)).available,"Oversized data is bounded")
    Thread.currentThread().interrupt()
    var cancelled=false
    try { LumoSpeechEnvelope.fromWave(bytes) } catch (_: CancellationException) { cancelled=true }
    finally { Thread.interrupted() }
    verify(cancelled,"Stop/destroy can interrupt off-main analysis")
    val actual=File(args.single()).readBytes();val measured=LumoSpeechEnvelope.fromWave(actual)
    verify(measured.available && measured.sampleRate==22050 && measured.channels==1,"Original apfel.wav PCM accepted without resampling")
    verify(measured.durationMs in 928..929,"Original 20463-frame word duration preserved")
    val values=(0 until measured.durationMs step 20).map { measured.amplitudeAt(it) }
    verify(values.any { it>.1 } && values.distinct().size>8,"Actual original voice has measured time-varying amplitude")
    verify(values.all { it.isFinite() && it in 0.0..1.0 },"Actual envelope remains finite and bounded")
    println("LUMO_SPEECH_ENVELOPE_PASS checks=$checks original_apfel_duration_ms=${measured.durationMs} bins=${values.size}")
}
