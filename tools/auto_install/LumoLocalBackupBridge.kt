package dev.ullmann.lumo

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

/** Android SAF transport. Only a reviewed restore is staged; no live Dart data is replaced. */
class LumoLocalBackupBridge(private val activity: Activity,
                           private val nativeIdle: () -> Boolean) {
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var callback: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private var working = false
    private var closed = false
    private val store get() = transaction(activity)
    val blocksGames: Boolean get() = working || callback != null || store.pending()

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "lumo_lernen/local_backup").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> background(result) {
                    mapOf("result" to store.status(), "previousAvailable" to store.hasPrevious(),
                        "pending" to store.pending())
                }
                "snapshotNative" -> background(result) {
                    requireIdle()
                    // AtomicFile repairs an interrupted event-store write before the snapshot.
                    GameEventStore.whileNoWriter(activity, 1000) {
                        requireIdle()
                        normalizeEventStore(activity)
                        store.captureFiles().map { (path, bytes) ->
                            // Navigation belongs to the old Activity, earned results do not.
                            val content = if (path == "lumo_game_events.json") {
                                val events = parsed(utf8(bytes))
                                events.remove("destination")
                                events.remove(GameEventStore.CALLER_RETURN_SESSION)
                                events.toString().toByteArray(Charsets.UTF_8)
                            } else bytes
                            mapOf("path" to path, "data" to content)
                        }
                    } ?: throw IllegalStateException("Game event writer is busy")
                }
                "pickBackup" -> pick(result, false, null)
                "saveBackup" -> {
                    val bytes = call.arguments as? ByteArray
                    if (bytes == null || bytes.size > LumoBackupTransaction.MAX_ARCHIVE) {
                        result.error("backup_invalid", "Ungültige Sicherungsdatei.", null)
                    } else pick(result, true, bytes)
                }
                "stageRestore" -> background(result) {
                    requireIdle()
                    val bytes = call.arguments as? ByteArray ?: error("Missing backup")
                    checkedArchive(bytes)
                    store.stage(bytes, processIdentity)
                    true
                }
                "stagePrevious" -> background(result) {
                    requireIdle(); store.stagePrevious(processIdentity); true
                }
                "closeForRestore" -> {
                    if (!store.pending() || !nativeIdle()) {
                        result.error("backup_pending", "Keine sichere Wiederherstellung vorgemerkt.", null)
                    } else {
                        result.success(null)
                        // The user explicitly chose 'restore and close'. A manual cold start
                        // avoids alarms, background-start permissions and old Dart caches.
                        main.postDelayed({
                            activity.finishAndRemoveTask()
                            android.os.Process.killProcess(android.os.Process.myPid())
                        }, 120)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun requireIdle() {
        check(nativeIdle()) { "Close the native game before backing up" }
    }
    private fun background(result: MethodChannel.Result, operation: () -> Any?) {
        if (working || callback != null || closed) {
            result.error("backup_busy", "Eine Datensicherung ist bereits geöffnet.", null); return
        }
        working = true
        worker.execute {
            try {
                val value = operation()
                main.post { working = false; if (!closed) result.success(value) }
            } catch (_: Exception) {
                main.post {
                    working = false
                    if (!closed) result.error("backup_failed",
                        "Die Datensicherung konnte nicht sicher abgeschlossen werden.", null)
                }
            }
        }
    }
    private fun pick(result: MethodChannel.Result, save: Boolean, bytes: ByteArray?) {
        if (working || callback != null || closed || store.pending()) {
            result.error("backup_busy", "Eine Datensicherung ist bereits geöffnet.", null); return
        }
        callback = result
        exportBytes = bytes
        try {
            val intent = Intent(if (save) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE).setType("application/json")
            if (save) intent.putExtra(Intent.EXTRA_TITLE,
                "Lumo-Sicherung-${SimpleDateFormat("yyyy-MM-dd-HHmm", Locale.ROOT).format(Date())}.json")
            else intent.putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "application/octet-stream", "text/plain"))
            activity.startActivityForResult(intent, if (save) SAVE_REQUEST else OPEN_REQUEST)
        } catch (_: Exception) {
            callback = null; exportBytes = null
            result.error("backup_picker", "Die Android-Dateiauswahl ist nicht verfügbar.", null)
        }
    }
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_REQUEST && requestCode != OPEN_REQUEST) return false
        val result = callback ?: return true
        callback = null
        val bytes = exportBytes; exportBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == SAVE_REQUEST) false else null); return true
        }
        if (uri.scheme != "content") {
            result.error("backup_uri", "Keine freigegebene Android-Datei gewählt.", null); return true
        }
        background(result) {
            if (requestCode == SAVE_REQUEST) {
                check(bytes != null)
                try {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { output ->
                        output.write(bytes); output.flush()
                    } ?: error("Output unavailable")
                    true
                } catch (error: Exception) {
                    // This URI was just created by ACTION_CREATE_DOCUMENT for this export.
                    try { DocumentsContract.deleteDocument(activity.contentResolver, uri) } catch (_: Exception) {}
                    throw error
                }
            } else {
                activity.contentResolver.openInputStream(uri)?.use {
                    LumoBackupTransaction.readLimited(it, LumoBackupTransaction.MAX_ARCHIVE)
                } ?: error("Input unavailable")
            }
        }
        return true
    }
    fun destroy() {
        closed = true
        callback?.success(null); callback = null; exportBytes = null
        worker.shutdown()
    }

    companion object {
        private const val OPEN_REQUEST = 8421
        private const val SAVE_REQUEST = 8422
        private const val PREFS = "FlutterSharedPreferences"
        private val processIdentity = java.util.UUID.randomUUID().toString()
        private const val LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!"
        private const val DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu"
        private val privateSettings = setOf("cloudVoiceEnabled", "localVoiceLicenseAccepted",
            "microphoneEnabled", "scannerEnabled", "aiProxyEnabled", "lanPlayEnabled", "ghostDuelEnabled")

        private fun transaction(context: Context) = LumoBackupTransaction(
            context.filesDir, File(context.noBackupFilesDir, "lumo-local-backup-v1"))

        /** Must run before super.onCreate(), hence before any Flutter plugin or Dart cache. */
        fun recoverBeforeFlutter(context: Context) {
            val store = transaction(context)
            if (!store.pending() && !store.recoveryRequired()) return
            // Activity rotation/recreation is not a cold start. The old process
            // may still own Dart repositories until closeForRestore kills it.
            if (!store.recoveryRequired() && store.stagedBy(processIdentity)) return
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            check(manager.runningAppProcesses.orEmpty().none {
                it.processName == "${context.packageName}:lumo_game"
            }) { "A native game is still active; restore is postponed" }
            val preferences = physicalPreferences(context)
            normalizeEventStore(context)
            if (store.recover(preferences)) return
            try {
                val previous = store.pendingPrevious()
                val archive = store.pendingArchive()
                val next = previous ?: archive?.let {
                    val checked = checkedArchive(it)
                    val merged = JSONObject(String(preferences.read(), Charsets.UTF_8))
                    for (key in merged.keys().asSequence().toList()) {
                        if (key.startsWith("flutter.") && allowedPreference(key.removePrefix("flutter."))) merged.remove(key)
                    }
                    val portable = checked.first
                    for (key in portable.keys()) {
                        val row = portable.getJSONObject(key)
                        val value = row.get("value")
                        val physical = when (row.getString("type")) {
                            "bool" -> raw("boolean", value)
                            "int" -> raw("long", value)
                            "double" -> raw("string", DOUBLE_PREFIX + (value as Number).toDouble().toString())
                            "string" -> raw("string", value)
                            "strings" -> raw("string", LIST_PREFIX + (value as JSONArray).toString())
                            else -> error("Unsupported preference")
                        }
                        merged.put("flutter.$key", physical)
                    }
                    LumoBackupTransaction.Snapshot(merged.toString().toByteArray(Charsets.UTF_8), checked.second)
                } ?: return
                store.apply(next, preferences)
            } catch (error: Exception) {
                if (store.recoveryRequired()) throw IllegalStateException(
                    "Restore recovery could not finish; originals retained", error)
                // A completed rollback is a usable old state. A rejected stage
                // never changed live data; do not loop on it on every app start.
                if (store.pending()) store.rejectPending()
            }
        }
        private fun utf8(bytes: ByteArray): String = Charsets.UTF_8.newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(bytes)).toString()
        private fun normalizeEventStore(context: Context) {
            val file = File(context.filesDir, "lumo_game_events.json")
            if (file.exists() || File(file.path + ".bak").exists()) {
                android.util.AtomicFile(file).openRead().use { }
            }
        }
        private fun parsed(source: String): JSONObject {
            var depth = 0
            var quoted = false
            var escaped = false
            for (character in source) {
                if (quoted) {
                    if (escaped) escaped = false
                    else if (character == '\\') escaped = true
                    else if (character == '"') quoted = false
                } else if (character == '"') quoted = true
                else if (character == '{' || character == '[') {
                    depth++; require(depth <= 64)
                } else if (character == '}' || character == ']') depth--
            }
            return JSONObject(source)
        }
        private fun hash(bytes: ByteArray): String = MessageDigest.getInstance("SHA-256")
            .digest(bytes).joinToString("") { "%02x".format(it.toInt() and 255) }
        private fun allowedPreference(key: String): Boolean {
            if (key.isEmpty() || key.length > 1024 || '\u0000' in key) return false
            val scope = key.startsWith("lumo_") || key.startsWith("lumo.") ||
                key.startsWith("cross_grade_practice_v1:") || key.startsWith("cross_grade_writing_v1:")
            return scope && !Regex("(^|[_.:])(api_?key|access_?token|refresh_?token|token|password|credential|secret|pin|premium|entitlement|permission|consent|license|auth|device_id|installation_id)([_.:]|$)",
                RegexOption.IGNORE_CASE).containsMatchIn(key)
        }
        private fun checkedArchive(bytes: ByteArray): Pair<JSONObject, Map<String, ByteArray>> {
            require(bytes.isNotEmpty() && bytes.size <= LumoBackupTransaction.MAX_ARCHIVE)
            val root = parsed(utf8(bytes))
            require(root.length() == 5 && root.getString("format") == "lumo-local-backup" && root.get("version") == 1)
            require(root.getString("createdAt").matches(Regex("[0-9]{4}-[0-9T:.+-]+Z")))
            val payload = root.getString("payload")
            require(hash(payload.toByteArray(Charsets.UTF_8)) == root.getString("sha256"))
            val body = parsed(payload)
            require(body.length() == 2)
            val prefs = body.getJSONObject("preferences")
            require(prefs.length() <= 20000 && prefs.toString().toByteArray().size <= LumoBackupTransaction.MAX_PREFS)
            for (key in prefs.keys()) {
                require(allowedPreference(key))
                val row = prefs.getJSONObject(key)
                require(row.length() == 2)
                val value = row.get("value")
                require(when (row.getString("type")) {
                    "bool" -> value is Boolean
                    "int" -> value is Int || value is Long
                    "double" -> value is Number && value.toDouble().isFinite()
                    "string" -> value is String && !value.startsWith("VGhpcyBpcyB0aGUgcHJlZml4IGZvci")
                    "strings" -> value is JSONArray && (0 until value.length()).all { value.get(it) is String }
                    else -> false
                })
                if (key == "lumo_app_settings_v1") {
                    val settings = parsed(value as String)
                    require(privateSettings.all { settings.opt(it) == false })
                    require(settings.optString("aiProxyUrl") == "https://lumo-ai-proxy.onrender.com")
                    val portableSettings = setOf("dailyGoal", "requireDailyMissionForGames", "missionTasksPerStation",
                        "soundEnabled", "voiceEnabled", "autoReadEnabled", "aiLearningMode", "aiProxyUrl", "reduceAnimations",
                        "largeText", "calmMode", "learningMode", "voiceRate", "voicePitch") + privateSettings
                    require(settings.keys().asSequence().all { it in portableSettings })
                }
            }
            if (prefs.has("lumo_3d_profile_keys_v1")) {
                require(prefs.getJSONObject("lumo_3d_save_salt_v1").getString("value").isNotEmpty())
            }
            val files = body.getJSONArray("nativeFiles")
            require(files.length() <= 1024)
            val result = linkedMapOf<String, ByteArray>()
            var total = 0L
            for (i in 0 until files.length()) {
                val file = files.getJSONObject(i)
                require(file.length() == 4)
                val path = file.getString("path")
                require(LumoBackupTransaction.ownedPath(path) && path !in result)
                val length = file.getInt("bytes")
                val data = file.getString("data")
                require(length in 0..LumoBackupTransaction.MAX_FILE &&
                    data.length <= ((LumoBackupTransaction.MAX_FILE + 2) / 3) * 4)
                val content = Base64.decode(data, Base64.NO_WRAP)
                require(content.size == length && hash(content) == file.getString("sha256"))
                val text = utf8(content)
                require('\u0000' !in text)
                if (!path.endsWith(".cfg")) parsed(text)
                total += content.size
                require(total <= LumoBackupTransaction.MAX_NATIVE)
                result[path] = content
            }
            return prefs to result
        }
        private fun raw(kind: String, value: Any) = JSONObject().put("kind", kind).put("value", value)
        private fun physicalPreferences(context: Context): LumoBackupTransaction.Preferences {
            val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return object : LumoBackupTransaction.Preferences {
                override fun read(): ByteArray {
                    val result = JSONObject()
                    for ((key, value) in preferences.all) {
                        result.put(key, when (value) {
                            is String -> raw("string", value)
                            is Boolean -> raw("boolean", value)
                            is Int -> raw("int", value)
                            is Long -> raw("long", value)
                            is Float -> raw("float", value)
                            is Set<*> -> raw("set", JSONArray(value.toList()))
                            else -> error("Unsupported stored preference")
                        })
                    }
                    return result.toString().toByteArray(Charsets.UTF_8)
                }
                override fun write(bytes: ByteArray) {
                    val source = JSONObject(utf8(bytes))
                    val editor = preferences.edit().clear()
                    for (key in source.keys()) {
                        val row = source.getJSONObject(key)
                        when (row.getString("kind")) {
                            "string" -> editor.putString(key, row.getString("value"))
                            "boolean" -> editor.putBoolean(key, row.getBoolean("value"))
                            "int" -> editor.putInt(key, row.getInt("value"))
                            "long" -> editor.putLong(key, row.getLong("value"))
                            "float" -> editor.putFloat(key, row.getDouble("value").toFloat())
                            "set" -> {
                                val list = row.getJSONArray("value")
                                editor.putStringSet(key, (0 until list.length()).map { list.getString(it) }.toSet())
                            }
                            else -> error("Unknown rollback preference")
                        }
                    }
                    check(editor.commit()) { "Preferences restore was not committed" }
                }
            }
        }
    }
}
