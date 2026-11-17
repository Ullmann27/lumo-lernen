"""Exercise the real private Memory/Quiz Android transport on the JVM.

The existing C4 tests supply Android/Godot/Flutter boundary adapters and a
deterministic main looper. JSON parsing, mailbox writes, token/game ownership,
the Java intent validator and durable return storage are production sources.
This is not an Android device, Godot render or Dart reward test.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import urllib.request

import test_connect_four_native_contract as boundary
from test_cards_lifecycle_heartbeat import missing_toolchain
from test_game_return_contract import ATOMIC_FILE, JSON_SHA256, JSON_URL

ROOT = Path(__file__).resolve().parents[2]

HARNESS = r'''
package dev.ullmann.lumo
import android.content.*
import android.os.*
import android.util.AtomicFile
import io.flutter.plugin.common.*
import org.godotengine.godot.Godot
import org.json.JSONObject
import java.io.File

object TableGamesRegression {
    private val token="a".repeat(32);private val other="b".repeat(32)
    private val round="c".repeat(32);private val owner="d".repeat(64)
    private val caller="11111111-1111-4111-8111-111111111111"
    private lateinit var game:String
    private fun state(ack:Int=0,rejected:Int=0,revision:Int=1)=JSONObject().put("schema",1)
        .put("game",game).put("token",token).put("owner",owner).put("roundId",round)
        .put("revision",revision).put("ack",ack).put("rejected",rejected)
    private fun call(method:String,tk:String=token,raw:String="{}",success:Boolean=true):Any? {
        var result:Any?=null;var error=false
        MethodChannel.handler!!(MethodCall(method,mapOf("token" to tk,"state" to raw)),object:MethodChannel.Result{
            override fun success(value:Any?){result=value}
            override fun error(code:String,message:String?,details:Any?){error=true}
            override fun notImplemented(){error=true}
        });check(error!=success){"Unexpected channel result for $method"};return result
    }
    private fun request(action:String=if(game=="memory")"flip" else "select",sequence:Int=1,revision:Int=1)=JSONObject()
        .put("token",token).put("roundId",round).put("revision",revision)
        .put("sequence",sequence).put("action",action).apply{
            if(action=="flip")put("index",3)
            if(action=="select")put("option",2)
        }
    private fun submit(value:JSONObject)=TableGamesBridge.submit(Hooks.root,token,game,value.toString())
    private fun sessionFile(name:String)=File(Hooks.root,"lumo_table_games_session_v1/$token/$name")
    private fun lifecycle()=JSONObject(sessionFile("lifecycle.json").readText())
    private fun open(){
        TableGamesBridge.attach(object:BinaryMessenger{},Hooks.root)
        call("open",raw=state().toString())
    }
    private fun binder()=TableAuthorityService().onBind(Intent()
        .putExtra("tableToken",token).putExtra("tableGame",game))!!
    private fun activity(connected:Boolean=true):TableGameActivity{
        val a=TableGameActivity()
        a.intent=Intent().putExtra("lumoLaunchOptions",JSONObject().put("game",game)
            .put("tableToken",token).put("sessionId",caller).toString())
            .putExtra(GameEventStore.CALLER_RETURN_SESSION,caller)
        a.onCreate(Bundle());a.onStart();a.onResume()
        if(connected)Hooks.connection!!.onServiceConnected(ComponentName(),binder())
        return a
    }
    @JvmStatic fun main(args:Array<String>){
        game=args[1];check(game in setOf("memory","quiz"))
        Hooks.root=File(args[2]).apply{mkdirs()};open()
        when(args[0]){
            "mailbox" -> {
                check(submit(request()));check(submit(request()));check(!submit(request(sequence=2)))
                val actual=JSONObject(call("poll") as String).getJSONObject("request")
                check(actual.getString("action")==if(game=="memory")"flip" else "select")
                check(actual.getLong("sequence")==1L)
                call("publish",raw=state(ack=1,revision=2).toString())
                check(!submit(request(sequence=2,revision=1)))
                check(submit(request(sequence=2,revision=2)))
            }
            "invalid-intents" -> {
                for(v in listOf(request().put("token",other),request().put("roundId",other),
                    request().put("revision",2),request().put("sequence",0),request().put("reward",100),
                    request(if(game=="memory")"select" else "flip"),request("cards_play"))){check(!submit(v))}
                val key=if(game=="memory")"index" else "option"
                check(!submit(request().put(key,if(game=="memory")24 else 4)))
                val raw=request().toString().replace(if(game=="memory")"\"index\":3" else "\"option\":2",
                    if(game=="memory")"\"index\":3.0" else "\"option\":2.0")
                check(!TableGamesBridge.submit(Hooks.root,token,game,raw))
                check(!TableGamesBridge.submit(Hooks.root,token,game,"x".repeat(2049)))
                check(!TableGamesBridge.submit(Hooks.root,token,if(game=="memory")"quiz" else "memory",request().toString()))
                check(submit(request()))
            }
            "owner-and-revision" -> {
                val before=sessionFile("state.json").readBytes()
                for(bad in listOf(state(revision=2).put("owner","e".repeat(64)),
                    state(revision=2).put("game",if(game=="memory")"quiz" else "memory"),state())){
                    call("publish",raw=bad.toString(),success=false);check(sessionFile("state.json").readBytes().contentEquals(before))
                }
                call("publish",raw=state(ack=2,rejected=1,revision=2).toString())
                call("publish",raw=state(ack=1,rejected=1,revision=3).toString(),success=false)
                call("publish",raw=state(ack=2,rejected=0,revision=3).toString(),success=false)
                check(JSONObject(TableGamesBridge.state(Hooks.root,token,game)).getString("owner")==owner)
            }
            "pending-terminal" -> {
                check(submit(request()));call("publish",raw=state(rejected=1,revision=2).toString())
                check(submit(request("resume",2,2)))
                call("publish",raw=state(ack=2,rejected=1,revision=3).toString())
                check(submit(request(sequence=3,revision=3)))
            }
            "publish-write-failure" -> {
                val before=sessionFile("state.json").readBytes()
                check(sessionFile("state.json.tmp").mkdir())
                call("publish",raw=state(revision=2).toString(),success=false)
                check(sessionFile("state.json").readBytes().contentEquals(before))
                check(sessionFile("state.json.tmp").delete())
                call("publish",raw=state(revision=2).toString())
                check(JSONObject(TableGamesBridge.state(Hooks.root,token,game)).getInt("revision")==2)
            }
            "authority" -> {
                val service=TableAuthorityService()
                check(service.onBind(Intent().putExtra("tableToken",other).putExtra("tableGame",game))==null)
                check(service.onBind(Intent().putExtra("tableToken",token)
                    .putExtra("tableGame",if(game=="memory")"quiz" else "memory"))==null)
                val remote=binder();check(TableAuthorityService.available(remote,token,game))
                check(!TableAuthorityService.available(remote,other,game))
                call("close");check(!TableAuthorityService.available(remote,token,game))
                check(!TableGamesBridge.pulse(Hooks.root,token,game,true));check(!submit(request()))
                call("open",tk=other,raw=state().put("token",other).toString())
                call("close",tk=token);check(TableGamesBridge.hasAuthority(other,game))
                TableGamesBridge.detach();check(!TableGamesBridge.hasAuthority(other,game))
            }
            "render-stall" -> {
                val a=activity();repeat(12){TestLooper.advance(500);check(lifecycle().getBoolean("active"));check(TestLooper.queue.size==1)}
                check(a.state()!="{}");check(!a.finished)
            }
            "pause-stale" -> {
                val a=activity();val stale=TestLooper.queue.single().task
                a.onPause();val before=lifecycle().toString();stale.run();TestLooper.advance(4000)
                check(!lifecycle().getBoolean("active"));check(lifecycle().getLong("pauseEpoch")==1L)
                check(lifecycle().toString()==before);check(!a.submit(request().toString()));check(a.state()=="{}")
                a.onResume();check(lifecycle().getBoolean("active"));check(TestLooper.queue.size==1)
            }
            "stop-resume" -> {
                val a=activity();val stale=TestLooper.queue.single().task
                a.onPause();a.onStop();stale.run();check(TestLooper.queue.isEmpty());check(Hooks.unbound==1)
                a.onStart();a.onResume();check(!lifecycle().getBoolean("active"))
                Hooks.connection!!.onServiceConnected(ComponentName(),binder());check(lifecycle().getBoolean("active"))
                a.onDestroy();stale.run();TestLooper.advance(5000);check(!lifecycle().getBoolean("active"))
            }
            "closed-mailbox" -> {
                val a=activity();call("close");TestLooper.advance(500)
                check(a.finished);check(a.state()=="{}");check(!a.submit(request().toString()))
                a.onResume();TestLooper.advance(4000);check(!sessionFile("state.json").exists())
            }
            "bind-timeout" -> {
                val a=activity(false);TestLooper.advance(4999);check(!a.finished)
                TestLooper.advance(1);check(a.finished);check(a.state()=="{}")
            }
            "return-durable" -> {
                val a=activity();check(a.returnToApp());check(a.finished)
                val saved=JSONObject(GameEventStore.pending(a))
                check(saved.getString("destination")=="games");check(saved.getString(GameEventStore.CALLER_RETURN_SESSION)==caller)
                check(!lifecycle().getBoolean("active"));check(a.returnToApp());TestLooper.advance(500);check(Process.kills==1)
                a.onResume();check(!lifecycle().getBoolean("active"))
            }
            "return-write-failure" -> {
                val a=activity();AtomicFile.failNextWrite=true
                check(!a.returnToApp());check(!a.finished);check(Process.kills==0);check(lifecycle().getBoolean("active"))
                check(a.returnToApp());check(a.finished);TestLooper.advance(500);check(Process.kills==1)
            }
            "plugin-isolation" -> {
                val a=activity();val plugin=a.getHostPlugins(Godot()).single() as TableGamesHostPlugin
                check(plugin.getPluginName()=="LumoHost");check(!plugin.reward("{\"stars\":100}"))
                check(plugin.submitTableAction(request().toString()));check(plugin.getTableState()!="{}")
                check(a.getCommandLine().contains("gl_compatibility"))
            }
            else -> error("Unknown scenario")
        };println("TABLE_GAMES_NATIVE_PASS ${args[0]} $game")
    }
}
'''


class TableGamesNativeContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        java = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(java) if java.is_file() else shutil.which('java')
        gradle = shutil.which('gradle')
        choices = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                   Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        if gradle:
            choices.append(Path(gradle).resolve().parents[1] / 'lib')
        libs = next((p for p in choices if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        if not cls.java or not libs:
            missing_toolchain('Existing verified JDK/Gradle Kotlin libraries are required; no compiler downloads')
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-table-native-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        supplied = os.environ.get('LUMO_TEST_JSON_JAR')
        if supplied:
            data = Path(supplied).read_bytes()
        else:
            with urllib.request.urlopen(JSON_URL, timeout=60) as response:
                data = response.read()
        if hashlib.sha256(data).hexdigest() != JSON_SHA256:
            raise RuntimeError('Existing pinned org.json dependency changed')
        jar = cls.work / 'json.jar'
        jar.write_bytes(data)
        classes = cls.work / 'classes'
        classes.mkdir()
        atomic = cls.work / 'AtomicFile.java'
        atomic.write_text(ATOMIC_FILE)
        cls.run_checked([cls.java, '--module', 'jdk.compiler/com.sun.tools.javac.Main',
                         '-source', '8', '-target', '8', '-d', str(classes), str(atomic),
                         str(ROOT / 'tools/auto_install/TableGameIntent.java')])
        for name, text in {**boundary.STUBS, 'TableGamesRegression.kt': HARNESS}.items():
            (cls.work / name).write_text(text)
        cls.classpath = os.pathsep.join(map(str, [classes, jar, next(libs.glob('kotlin-stdlib-*.jar'))]))
        sources = [ROOT / 'tools/auto_install' / (name + '.kt') for name in
                   ('TableGameActivity', 'TableGamesBridge', 'TableAuthorityService',
                    'ConnectFourGameActivity', 'ConnectFourBridge', 'ConnectFourAuthorityService', 'GameEventStore')]
        cls.run_checked([cls.java, '-cp', os.pathsep.join(map(str, libs.glob('*.jar'))),
                         'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                         '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(classes),
                         *map(str, cls.work.glob('*.kt')), *map(str, sources)])
        for name in ('TableGameIntent', 'TableGameActivity', 'TableGamesBridge', 'TableAuthorityService'):
            bytecode = (classes / 'dev/ullmann/lumo' / (name + '.class')).read_bytes()
            if bytecode[:4] != b'\xca\xfe\xba\xbe' or int.from_bytes(bytecode[6:8], 'big') != 52:
                raise AssertionError('Expected actual Java 8 bytecode for ' + name)

    @classmethod
    def run_checked(cls, command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def scenario(self, name, game):
        result = self.run_checked([self.java, '-cp', self.classpath,
                                  'dev.ullmann.lumo.TableGamesRegression', name, game,
                                  str(self.work / (name + '-' + game))])
        self.assertIn('TABLE_GAMES_NATIVE_PASS ' + name + ' ' + game, result.stdout)
        print(result.stdout.strip())


for _game in ('memory', 'quiz'):
    for _scenario in ('mailbox', 'invalid-intents', 'owner-and-revision', 'pending-terminal',
                      'publish-write-failure', 'authority', 'render-stall', 'pause-stale',
                      'stop-resume', 'closed-mailbox', 'bind-timeout', 'return-durable',
                      'return-write-failure', 'plugin-isolation'):
        setattr(TableGamesNativeContractTest, 'test_' + _game + '_' + _scenario.replace('-', '_'),
                lambda self, name=_scenario, game=_game: self.scenario(name, game))

if __name__ == '__main__':
    unittest.main()
