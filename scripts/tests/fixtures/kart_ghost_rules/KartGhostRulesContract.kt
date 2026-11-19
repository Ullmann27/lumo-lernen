package dev.ullmann.lumo

import java.io.ByteArrayInputStream
import java.io.File

fun main(args: Array<String>) {
    var checks = 0
    fun check(ok: Boolean, label: String) {
        checks++
        if (!ok) throw AssertionError(label)
    }
    val ghost = File(args[0]).readBytes()
    check(KartGhostRules.looksLikeGhost(ghost), "Godot-Geist erkannt")
    check(!KartGhostRules.looksLikeGhost(null), "null abgelehnt")
    check(!KartGhostRules.looksLikeGhost("%PDF-1.7 ......................................".toByteArray()), "PDF abgelehnt")
    check(!KartGhostRules.looksLikeGhost(ghost.copyOf(20)), "zu kurz abgelehnt")
    check(!KartGhostRules.looksLikeGhost(ByteArray(65537).also { it[0] = 0x4C; it[1] = 0x47; it[2] = 0x53; it[3] = 0x54 }), "zu groß abgelehnt")
    check(KartGhostRules.readLimited(ByteArrayInputStream(ghost))!!.contentEquals(ghost), "Lesen vollständig")
    check(KartGhostRules.readLimited(ByteArrayInputStream(ByteArray(65537))) == null, "Lesen bricht über 64 KB ab")
    check(KartGhostRules.readLimited(ByteArrayInputStream(ByteArray(65536)))!!.size == 65536, "64 KB noch erlaubt")
    check(KartGhostRules.isLaunchText("LUMOGEIST1:" + "A".repeat(40)), "Textform erlaubt")
    check(!KartGhostRules.isLaunchText("LUMOGEIST1:" + "A".repeat(39)), "Textform zu kurz")
    check(!KartGhostRules.isLaunchText("LUMOGEIST1:" + "A".repeat(40) + "/"), "Textform fremdes Zeichen")
    check(!KartGhostRules.isLaunchText("LUMOGEIST1:" + "A".repeat(87383)), "Textform zu lang")
    check(!KartGhostRules.isLaunchText(null), "keine Textform")
    check(KartGhostRules.playerName("  Jürgen<b>  ") == "Jürgenb", "Name gereinigt")
    check(KartGhostRules.playerName("Maximilian Alexander") == "Maximilian Alexa", "Name max. 16")
    check(KartGhostRules.playerName(null) == "", "kein Name")
    check(KartGhostRules.fileName("../../etc/passwd") == "etc_passwd.lumogeist", "Dateiname ohne Pfad")
    check(KartGhostRules.fileName("Lumo-Geist_Lena_sonnenhafen.lumogeist") == "Lumo-Geist_Lena_sonnenhafen.lumogeist", "Dateiname bleibt")
    check(KartGhostRules.fileName("") == "Lumo-Geist.lumogeist", "Dateiname Vorgabe")
    check(!KartGhostRules.shareText("Hallo\u0000\nWelt").contains('\u0000'), "Teilen-Text ohne Steuerzeichen")
    println("LUMO_KART_GHOST_RULES_PASS checks=$checks")
}
