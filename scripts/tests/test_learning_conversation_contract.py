"""Execute production native dialogue gates at a synthetic Android boundary.

This compiles the actual Kotlin controller and Java logic with the existing
JDK/Kotlin/JSON tools. Fixtures expose queued callbacks; they do not recognize
speech, play Android audio or claim device acceptance.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
JSON_SHA256 = '3cf6cd6892e32e2b4c1c39e0f52f5248a2f5b37646fdfbb79a66b46b618414ed'
FIXTURES = {
    'Activity.kt': '''package android.app
class Activity {
  var permission = true
  fun checkSelfPermission(name: String): Int = if (permission) 0 else -1
  fun requestPermissions(names: Array<String>, code: Int) {}
}
''',
    'Manifest.kt': '''package android
object Manifest { object permission { const val RECORD_AUDIO = "record_audio" } }
''',
    'PackageManager.kt': '''package android.content.pm
object PackageManager { const val PERMISSION_GRANTED = 0 }
''',
    'Intent.kt': '''package android.content
class Intent(val action: String) {
  fun putExtra(key: String, value: Any?): Intent = this
}
''',
    'Os.kt': '''package android.os
object Build { object VERSION { var SDK_INT = 36 }; object VERSION_CODES { const val S = 31 } }
class Bundle(val words: ArrayList<String> = arrayListOf()) {
  fun getStringArrayList(key: String): ArrayList<String> = words
}
class Looper { companion object { fun getMainLooper() = Looper() } }
class Handler(looper: Looper) {
  fun post(work: Runnable): Boolean { queue.add(work); return true }
  fun postDelayed(work: Runnable, delay: Long): Boolean { delayed.add(work); return true }
  companion object {
    val queue = mutableListOf<Runnable>()
    val delayed = mutableListOf<Runnable>()
    fun drain() { while (queue.isNotEmpty()) queue.removeAt(0).run() }
  }
}
''',
    'Speech.kt': '''package android.speech
import android.app.Activity
import android.content.Intent
import android.os.Bundle
interface RecognitionListener {
  fun onReadyForSpeech(params: Bundle?)
  fun onBeginningOfSpeech()
  fun onRmsChanged(rmsdB: Float)
  fun onBufferReceived(buffer: ByteArray?)
  fun onEndOfSpeech()
  fun onError(error: Int)
  fun onResults(results: Bundle?)
  fun onPartialResults(partialResults: Bundle?)
  fun onEvent(eventType: Int, params: Bundle?)
}
object RecognizerIntent {
  const val ACTION_RECOGNIZE_SPEECH = "recognize"
  const val EXTRA_LANGUAGE_MODEL = "model"
  const val LANGUAGE_MODEL_FREE_FORM = "free"
  const val EXTRA_LANGUAGE = "language"
  const val EXTRA_PREFER_OFFLINE = "offline"
  const val EXTRA_PARTIAL_RESULTS = "partial"
  const val EXTRA_MAX_RESULTS = "maximum"
}
class SpeechRecognizer {
  lateinit var callback: RecognitionListener
  var destroyed = false
  var started = false
  fun setRecognitionListener(value: RecognitionListener) { callback = value }
  fun startListening(intent: Intent) { check(!destroyed); started = true }
  fun stopListening() { started = false }
  fun cancel() { started = false }
  fun destroy() { destroyed = true; started = false }
  companion object {
    const val RESULTS_RECOGNITION = "results"
    var available = true
    val created = mutableListOf<SpeechRecognizer>()
    fun isOnDeviceRecognitionAvailable(activity: Activity) = available
    fun createOnDeviceSpeechRecognizer(activity: Activity): SpeechRecognizer =
      SpeechRecognizer().also { created.add(it) }
  }
}
''',
}

CONTRACT = r'''
package dev.ullmann.lumo
import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.speech.SpeechRecognizer
import org.json.JSONArray
import org.json.JSONObject

private var checks = 0
private fun verify(condition: Boolean, message: String) {
  checks++
  check(condition) { message }
}
private fun scope(step: String = "first", revision: Int = 0, task: String = "task-one") =
  JSONObject().put("protocolVersion", 1).put("sessionId", "native-launch")
    .put("taskId", task).put("stepId", step).put("revision", revision).put("cancelEpoch", 0)
private fun options(actions: List<String>? = listOf("explain", "repeat", "slower", "hint", "stop")) =
  JSONObject().put("sessionId", "native-launch").put("learningMicrophoneEnabled", true)
    .put("learning", JSONObject().put("kind", "task_card").put("scope", scope())
      .put("explanation", "FIRST checked explanation").put("objectIds", JSONArray(listOf("task_prompt")))
      .also { if (actions != null) it.put("allowedActions", JSONArray(actions)) })
private fun request(turn: Int, action: String = "explain", text: String = "Warum?",
                    identity: JSONObject = scope()) =
  JSONObject().put("scope", identity).put("turnId", turn).put("action", action).put("text", text).toString()
private fun update(step: String = "second", revision: Int = 1, task: String = "task-one",
                   help: String = "SECOND checked explanation", actions: List<String> = listOf("explain", "repeat", "stop")) =
  JSONObject().put("scope", scope(step, revision, task)).put("explanation", help)
    .put("objectIds", JSONArray(listOf("task_prompt"))).put("allowedActions", JSONArray(actions)).toString()
private fun state(controller: LumoLearningConversation) = JSONObject(controller.status())

fun main() {
  var audioStops = 0
  fun controller(actions: List<String>? = listOf("explain", "repeat", "slower", "hint", "stop")) =
    LumoLearningConversation(Activity(), options(actions)) { audioStops++ }.also { it.setActive(true) }

  val missing = controller(null)
  verify(!missing.request(request(1)), "Missing host permissions must deny help")
  verify(missing.request(request(2, "explain", "Stopp")), "Spoken Stop remains available")
  Handler.drain()
  verify(state(missing).getString("state") == "cancelled", "Stop must cancel")
  verify(!missing.updateContext(update()), "Native scene must not widen missing host permissions")

  val restricted = controller(listOf("explain", "stop"))
  verify(restricted.request(request(1, text = "Langsamer")), "Explicit explain request reaches final action gate")
  Handler.drain()
  verify(state(restricted).getString("state") == "unavailable", "Derived slower must be checked again")
  verify(!state(restricted).getString("reply").contains("FIRST"), "Denied inference must not reveal help")
  verify(state(restricted).getString("objectId").isEmpty(), "Denied inference must not publish object focus")

  val current = controller()
  verify(current.request(request(1)), "Allowed current task can explain")
  Handler.drain()
  verify(state(current).getString("reply") == "FIRST checked explanation", "First checked explanation is used")
  val stopsBeforeUpdate = audioStops
  verify(current.updateContext(update()), "Monotone same-task step update is accepted")
  Handler.drain()
  verify(audioStops == stopsBeforeUpdate + 1, "Step change stops actual audio owner")
  verify(current.request(request(2, "repeat", "Noch einmal", scope("second", 1))), "Repeat new step")
  Handler.drain()
  verify(state(current).getString("reply") == "SECOND checked explanation", "Repeat cannot resurrect prior step")
  verify(!current.request(request(3)), "Old step/revision cannot request a reply")

  val queued = controller()
  verify(queued.request(request(1)), "Queue old explanation")
  verify(queued.updateContext(update()), "Replace context before UI thread executes")
  Handler.drain()
  verify(state(queued).getString("reply").isEmpty(), "Late queued explanation is discarded")
  verify(state(queued).getString("stepId") == "second", "Snapshot belongs to new step")

  val microphone = controller()
  verify(microphone.startListening(request(1)), "Explicit local microphone start accepted")
  Handler.drain()
  val firstCapture = SpeechRecognizer.created.last()
  verify(state(microphone).getString("state") == "starting", "No listening claim before native readiness")
  firstCapture.callback.onReadyForSpeech(null)
  verify(state(microphone).getString("state") == "listening", "Real boundary readiness enables listening state")
  verify(microphone.updateContext(update()), "Step change during recognition")
  Handler.drain()
  val afterStep = microphone.status()
  firstCapture.callback.onResults(Bundle(arrayListOf("old thirteen")))
  firstCapture.callback.onError(1)
  verify(microphone.status() == afterStep && firstCapture.destroyed, "Old callbacks cannot revive after step change")

  verify(microphone.startListening(request(2, identity = scope("second", 1))), "New explicit capture accepted")
  Handler.drain()
  val finalCapture = SpeechRecognizer.created.last()
  finalCapture.callback.onResults(Bundle(arrayListOf("thirteen")))
  val finalState = microphone.status()
  verify(state(microphone).getString("state") == "transcribed", "Final result is only a candidate")
  finalCapture.callback.onResults(Bundle(arrayListOf("duplicate")))
  finalCapture.callback.onError(1)
  verify(microphone.status() == finalState, "Completed capture callbacks are terminal")

  val paused = controller()
  verify(paused.startListening(request(1)), "Start before pause")
  Handler.drain()
  val pauseCapture = SpeechRecognizer.created.last()
  val captureCount = SpeechRecognizer.created.size
  paused.setActive(false)
  paused.setActive(true)
  Handler.drain()
  val afterResume = paused.status()
  pauseCapture.callback.onResults(Bundle(arrayListOf("late")))
  verify(paused.status() == afterResume, "Late result after resume is discarded")
  verify(SpeechRecognizer.created.size == captureCount && pauseCapture.destroyed, "Resume cannot reopen the microphone")

  val stopped = controller()
  stopped.stop()
  val oldStop = Handler.queue.removeAt(0)
  verify(stopped.request(request(1)), "New explicit turn after stop")
  Handler.drain()
  val newTurn = stopped.status()
  oldStop.run()
  verify(stopped.status() == newTurn, "Late stop cleanup cannot overwrite a newer explicit turn")

  val taskSwitch = controller()
  verify(taskSwitch.request(request(1)), "Old task initially available")
  Handler.drain()
  val beforeTaskChange = audioStops
  val newTask = JSONObject(update(task = "task-two", revision = 0)).put("kind", "bridge_ten").toString()
  verify(!taskSwitch.updateContext(newTask), "New task needs a new descriptor launch")
  Handler.drain()
  verify(audioStops == beforeTaskChange + 1, "Task change stops old audio")
  verify(!taskSwitch.request(request(2)), "Old task remains retired after attempted task switch")
  verify(!taskSwitch.startListening(request(3)), "Retired task cannot start microphone")
  println("LUMO_NATIVE_DIALOGUE_GATES_PASS checks=$checks boundary=synthetic_JVM no_Android_playback_claim=true")
}
'''


class LearningConversationContractTest(unittest.TestCase):
    def test_production_native_scope_permissions_and_stale_callbacks(self):
        jdk = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin'
        java = str(jdk / 'java') if (jdk / 'java').is_file() else shutil.which('java')
        javac = str(jdk / 'javac') if (jdk / 'javac').is_file() else shutil.which('javac')
        libraries = Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent'))
        json_jar = Path(os.environ.get('LUMO_JSON_JAR', '/nonexistent'))
        self.assertTrue(java and javac, 'Existing JDK required; no download fallback')
        self.assertTrue(list(libraries.glob('kotlin-compiler-embeddable-*.jar')), 'Set LUMO_KOTLIN_LIB_DIR')
        self.assertTrue(json_jar.is_file(), 'Set LUMO_JSON_JAR to the existing JSON20240303 JAR')
        self.assertEqual(hashlib.sha256(json_jar.read_bytes()).hexdigest(), JSON_SHA256)
        stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
        with tempfile.TemporaryDirectory(prefix='lumo-native-dialogue-gates-') as temporary:
            directory = Path(temporary)
            classes = directory / 'classes'
            classes.mkdir()
            sources = []
            for name, content in {**FIXTURES, 'Contract.kt': CONTRACT}.items():
                path = directory / name
                path.write_text(content)
                sources.append(path)
            runtime = os.pathsep.join(map(str, (classes, stdlib, json_jar)))
            commands = [
                [javac, '-encoding', 'UTF-8', '-d', str(classes),
                 str(ROOT / 'tools/auto_install/LumoLearningDialogLogic.java')],
                [java, '-cp', os.pathsep.join(map(str, libraries.glob('*.jar'))),
                 'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                 '-classpath', runtime, '-jvm-target', '17', '-d', str(classes),
                 str(ROOT / 'tools/auto_install/LumoLearningConversation.kt'), *map(str, sources)],
                [java, '-cp', runtime, 'dev.ullmann.lumo.ContractKt'],
            ]
            for command in commands:
                result = subprocess.run(command, capture_output=True, text=True, timeout=90)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('LUMO_NATIVE_DIALOGUE_GATES_PASS checks=37 ', result.stdout)
            print(result.stdout, end='')


if __name__ == '__main__':
    unittest.main()
