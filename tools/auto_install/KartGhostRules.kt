package dev.ullmann.lumo

import java.io.InputStream

/**
 * Regeln für „Lumo-Geist“-Dateien (Lumo Kart, Geister-Duell mit Freunden), ohne Android.
 * Der Host nimmt nur kleine Dateien mit der Kennung "LGST" an; Inhalt, Prüfsumme und
 * Strecke prüfen danach die App (Kopf) und das Spiel (alles). Nichts wird gespeichert,
 * bevor ein Mensch die Einladung angenommen hat.
 */
object KartGhostRules {
    const val MAX_BYTES = 65536
    const val MIME = "application/octet-stream"
    private const val MIN_BYTES = 43
    private val launchText = Regex("^LUMOGEIST1:[A-Za-z0-9_-]{40,87382}$")

    fun looksLikeGhost(data: ByteArray?): Boolean =
        data != null && data.size in MIN_BYTES..MAX_BYTES &&
            data[0] == 0x4C.toByte() && data[1] == 0x47.toByte() &&
            data[2] == 0x53.toByte() && data[3] == 0x54.toByte()

    /** Liest höchstens MAX_BYTES; größere Ströme ergeben null (nie ganz in den Speicher). */
    fun readLimited(input: InputStream): ByteArray? {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        var total = 0
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            total += read
            if (total > MAX_BYTES) return null
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }

    fun isLaunchText(text: String?): Boolean = text != null && launchText.matches(text)

    /** Vorname für das Namensschild: Buchstaben, Leerzeichen, Bindestrich, Apostroph; max. 16. */
    fun playerName(raw: String?): String {
        val kept = (raw ?: "").filter { it.isLetter() || it == ' ' || it == '-' || it == '\'' }
        return kept.replace(Regex(" +"), " ").trim().take(16).trim()
    }

    fun fileName(raw: String?): String {
        val base = (raw ?: "").removeSuffix(".lumogeist")
            .map { if (it.isLetterOrDigit() && it.code < 128 || it == '-' || it == '_') it else '_' }
            .joinToString("").trim('_').take(60)
        return (base.ifEmpty { "Lumo-Geist" }) + ".lumogeist"
    }

    fun shareText(raw: String?): String =
        (raw ?: "").filter { !it.isISOControl() }.take(160).trim() +
            "\nÖffne die Datei mit Lumo Lernen (Lumo Kart → Geister-Duell)."
}
