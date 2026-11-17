"""Compile the real C4 Activity, bridge, Binder service and original event store.

Only Android/Godot/Flutter boundary classes and the main looper are JVM adapters.
JSON parsing, mailbox files, private authority and durable return writes are real
production code. This does not claim an Android emulator or device execution.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import urllib.request

from test_cards_lifecycle_heartbeat import missing_toolchain
from test_game_return_contract import ATOMIC_FILE, JSON_SHA256, JSON_URL

ROOT = Path(__file__).resolve().parents[2]
STUBS = {
    'Os.kt': r'''
package android.os
class Bundle
interface IBinder {
    companion object { const val FIRST_CALL_TRANSACTION = 1 }
    fun transact(code: Int, data: Parcel, reply: Parcel, flags: Int): Boolean
}
open class Binder : IBinder {
    override fun transact(code: Int, data: Parcel, reply: Parcel, flags: Int) = onTransact(code,data,reply,flags)
    open fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int) = false
}
class Parcel {
    private val values = mutableListOf<Any?>(); private var index = 0
    companion object { fun obtain() = Parcel() }
    fun writeInterfaceToken(value: String) { writeString(value) }
    fun enforceInterface(value: String) { check(readString() == value) }
    fun writeString(value: String?) { values.add(value) }
    fun readString(): String? = values[index++] as String?
    fun writeInt(value: Int) { values.add(value) }
    fun readInt(): Int = values[index++] as Int
    fun writeNoException() { writeInt(0) }
    fun readException() { check(readInt() == 0) }
    fun recycle() {}
}
class Looper { companion object { private val main = Looper(); fun getMainLooper() = main } }
object TestLooper {
    data class Entry(val due: Long,val task: Runnable)
    var now = 0L; val queue = mutableListOf<Entry>()
    fun advance(ms: Long) { val until=now+ms; var calls=0
        while(true) { val next=queue.minByOrNull{it.due} ?: break
            if(next.due>until) break
            check(++calls<10000); queue.remove(next); now=next.due; next.task.run()
        }; now=until
    }
}
class Handler(looper: Looper) {
    fun postDelayed(task: Runnable, delay: Long): Boolean { TestLooper.queue.add(TestLooper.Entry(TestLooper.now+delay,task)); return true }
    fun removeCallbacks(task: Runnable) { TestLooper.queue.removeAll{it.task===task} }
}
object Process { var kills=0; fun myPid()=73; fun killProcess(pid:Int){kills++} }
''',
    'Content.kt': r'''
package android.content
import java.io.File
import android.os.IBinder
class ComponentName
interface ServiceConnection {
    fun onServiceConnected(name:ComponentName,remote:IBinder)
    fun onServiceDisconnected(name:ComponentName)
    fun onNullBinding(name:ComponentName)
    fun onBindingDied(name:ComponentName)
}
object Hooks { lateinit var root:File; var connection:ServiceConnection?=null; var unbound=0 }
open class Context {
    companion object { const val BIND_AUTO_CREATE=1 }
    val filesDir: File get()=Hooks.root
    fun bindService(intent:Intent,connection:ServiceConnection,flags:Int):Boolean { Hooks.connection=connection;return true }
    fun unbindService(connection:ServiceConnection){Hooks.unbound++}
}
class Intent {
    constructor();constructor(context:Context,type:Class<*>)
    private val values=mutableMapOf<String,Any?>()
    fun getStringExtra(name:String)=values[name] as String?
    fun putExtra(name:String,value:String?):Intent {values[name]=value;return this}
    fun putExtra(name:String,value:Int):Intent {values[name]=value;return this}
}
''',
    'Activity.kt': r'''
package android.app
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.IBinder
open class Activity:Context(){
    companion object {const val RESULT_OK=-1}
    var intent=Intent();var finished=false;var result:Intent?=null
    open fun onStart(){};open fun onStop(){};open fun onResume(){};open fun onPause(){}
    open fun onCreate(state:Bundle?){};open fun onDestroy(){}
    fun runOnUiThread(task:Runnable){task.run()}
    fun setResult(code:Int,intent:Intent){result=intent}
    fun finish(){finished=true}
}
open class Service:Context(){open fun onBind(intent:Intent?):IBinder?=null}
''',
    'Godot.kt': r'''
package org.godotengine.godot
import android.app.Activity
import org.godotengine.godot.plugin.GodotPlugin
class Godot
open class GodotActivity:Activity(){
    open fun getCommandLine():MutableList<String> = mutableListOf()
    open fun getHostPlugins(engine:Godot):Set<GodotPlugin> = emptySet()
    open fun onGodotForceQuit(instance:Godot){}
    open fun onGodotRestartRequested(instance:Godot){}
}
''',
    'Plugin.kt': r'''
package org.godotengine.godot.plugin
import org.godotengine.godot.Godot
annotation class UsedByGodot
open class GodotPlugin(engine:Godot){open fun getPluginName():String=""}
''',
    'Flutter.kt': r'''
package io.flutter.plugin.common
interface BinaryMessenger
class MethodCall(val method:String,private val args:Map<String,Any?>){
    @Suppress("UNCHECKED_CAST") fun <T> argument(name:String):T?=args[name] as T?
}
class MethodChannel(messenger:BinaryMessenger,name:String){
    interface Result {fun success(value:Any?);fun error(code:String,message:String?,details:Any?);fun notImplemented()}
    companion object {var handler:((MethodCall,Result)->Unit)?=null}
    fun setMethodCallHandler(value:(MethodCall,Result)->Unit){handler=value}
}
''',
}
HARNESS = r'''
package dev.ullmann.lumo
import android.content.*
import android.os.*
import android.util.AtomicFile
import io.flutter.plugin.common.*
import org.godotengine.godot.Godot
import org.json.JSONObject
import java.io.File

object ConnectFourRegression {
    private val token="a".repeat(32);private val other="b".repeat(32)
    private val round="c".repeat(32);private val owner="d".repeat(64)
    private val caller="11111111-1111-4111-8111-111111111111"
    private fun state(ack:Int=0,rejected:Int=0,revision:Int=1)=JSONObject().put("schema",1)
        .put("game","connect_four").put("token",token).put("owner",owner).put("roundId",round)
        .put("revision",revision).put("ack",ack).put("rejected",rejected)
    private fun call(method:String,tk:String=token,raw:String="{}",success:Boolean=true):Any? {
        var result:Any?=null;var error=false
        MethodChannel.handler!!(MethodCall(method,mapOf("token" to tk,"state" to raw)),object:MethodChannel.Result{
            override fun success(value:Any?){result=value}
            override fun error(code:String,message:String?,details:Any?){error=true}
            override fun notImplemented(){error=true}
        });check(error!=success){"Unexpected channel result for $method"};return result
    }
    private fun request(action:String="drop",sequence:Int=1,revision:Int=1)=JSONObject()
        .put("token",token).put("roundId",round).put("revision",revision)
        .put("sequence",sequence).put("action",action).apply{if(action=="drop")put("column",3)}
    private fun submit(value:JSONObject)=ConnectFourBridge.submit(Hooks.root,token,value.toString())
    private fun lifecycle()=JSONObject(File(Hooks.root,"lumo_connect_four_session_v1/$token/lifecycle.json").readText())
    private fun open(){
        ConnectFourBridge.attach(object:BinaryMessenger{},Hooks.root)
        call("open",raw=state().toString())
    }
    private fun activity(connected:Boolean=true):ConnectFourGameActivity{
        val a=ConnectFourGameActivity()
        a.intent=Intent().putExtra("lumoLaunchOptions",JSONObject().put("game","connect_four")
            .put("connectFourToken",token).put("sessionId",caller).toString())
            .putExtra(GameEventStore.CALLER_RETURN_SESSION,caller)
        a.onCreate(Bundle());a.onStart();a.onResume()
        if(connected) {val service=ConnectFourAuthorityService()
            val binder=service.onBind(Intent().putExtra("connectFourToken",token))!!
            Hooks.connection!!.onServiceConnected(ComponentName(),binder)
        };return a
    }
    @JvmStatic fun main(args:Array<String>){
        Hooks.root=File(args[1]).apply{mkdirs()};open()
        when(args[0]){
            "bridge-intents" -> {
                check(submit(request()));check(submit(request()));check(!submit(request(sequence=2)))
                val raw=JSONObject(call("poll") as String).getJSONObject("request")
                check(raw.getInt("column")==3&&raw.getLong("sequence")==1L)
                call("publish",raw=state(ack=1,revision=2).toString())
                check(submit(request(sequence=2,revision=2)))
            }
            "invalid-intents" -> {
                for(v in listOf(request().put("token",other),request().put("roundId",other),
                    request().put("column",7),request().put("revision",2),
                    request().put("reward",100),request("cards_play"),request().put("sequence",0))){check(!submit(v))}
                check(!ConnectFourBridge.submit(Hooks.root,token,request().toString().replace("\"column\":3", "\"column\":3.0")))
                check(!ConnectFourBridge.submit(Hooks.root,token,"x".repeat(2049)))
                check(submit(request()));call("publish",raw=state().put("owner","foreign").toString(),success=false)
                check(JSONObject(ConnectFourBridge.state(Hooks.root,token)).getString("owner")==owner)
            }
            "pending-terminal" -> {
                check(submit(request()));call("publish",raw=state(rejected=1,revision=2).toString())
                check(submit(request("resume",2,2)));call("publish",raw=state(ack=2,rejected=1,revision=3).toString())
                check(submit(request(sequence=3,revision=3)))
            }
            "authority" -> {
                val service=ConnectFourAuthorityService()
                check(service.onBind(Intent().putExtra("connectFourToken",other))==null)
                val binder=service.onBind(Intent().putExtra("connectFourToken",token))!!
                check(ConnectFourAuthorityService.available(binder,token));check(!ConnectFourAuthorityService.available(binder,other))
                call("close");check(!ConnectFourAuthorityService.available(binder,token))
                check(!ConnectFourBridge.pulse(Hooks.root,token,true));check(!submit(request()))
                call("open",tk=other,raw=state().put("token",other).toString())
                call("close",tk=token);check(ConnectFourBridge.hasAuthority(other))
            }
            "render-stall" -> {
                val a=activity();repeat(12){TestLooper.advance(500);check(lifecycle().getBoolean("active"));check(TestLooper.queue.size==1)}
                // Six virtual seconds, no renderer poll or touch; a visible bound host owns the only pulse.
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
                val binder=ConnectFourAuthorityService().onBind(Intent().putExtra("connectFourToken",token))!!
                Hooks.connection!!.onServiceConnected(ComponentName(),binder);check(lifecycle().getBoolean("active"))
                a.onDestroy();stale.run();TestLooper.advance(5000);check(!lifecycle().getBoolean("active"))
            }
            "closed-mailbox" -> {
                val a=activity();call("close");TestLooper.advance(500)
                check(a.finished);check(a.state()=="{}");check(!a.submit(request().toString()))
                a.onResume();TestLooper.advance(4000);check(!File(Hooks.root,"lumo_connect_four_session_v1/$token/state.json").exists())
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
                val a=activity();val plugin=a.getHostPlugins(Godot()).single() as ConnectFourHostPlugin
                check(plugin.getPluginName()=="LumoHost");check(!plugin.reward("{\"stars\":100}"))
                check(plugin.submitConnectFourAction(request().toString()));check(plugin.getConnectFourState()!="{}")
                check(a.getCommandLine().contains("gl_compatibility"))
            }
            else -> error("Unknown scenario")
        };println("CONNECT_FOUR_NATIVE_PASS ${args[0]}")
    }
}
'''


class ConnectFourNativeContractTest(unittest.TestCase):
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
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-c4-native-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        jar = cls.work / 'json.jar'
        supplied = os.environ.get('LUMO_TEST_JSON_JAR')
        if supplied:
            data = Path(supplied).read_bytes()
        else:
            with urllib.request.urlopen(JSON_URL, timeout=60) as response:
                data = response.read()
        if hashlib.sha256(data).hexdigest() != JSON_SHA256:
            raise RuntimeError('Existing pinned org.json dependency changed')
        jar.write_bytes(data)
        classes = cls.work / 'classes'
        classes.mkdir()
        atomic = cls.work / 'AtomicFile.java'
        atomic.write_text(ATOMIC_FILE)
        cls.run_checked([cls.java, '--module', 'jdk.compiler/com.sun.tools.javac.Main',
                         '-d', str(classes), str(atomic)])
        for name, text in {**STUBS, 'ConnectFourRegression.kt': HARNESS}.items():
            (cls.work / name).write_text(text)
        cls.classpath = os.pathsep.join(map(str, [classes, jar, next(libs.glob('kotlin-stdlib-*.jar'))]))
        sources = [ROOT / 'tools/auto_install' / (name + '.kt') for name in
                   ('ConnectFourGameActivity', 'ConnectFourBridge', 'ConnectFourAuthorityService', 'GameEventStore')]
        cls.run_checked([cls.java, '-cp', os.pathsep.join(map(str, libs.glob('*.jar'))),
                         'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                         '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(classes),
                         *map(str, cls.work.glob('*.kt')), *map(str, sources)])

    @classmethod
    def run_checked(cls, command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def scenario(self, name):
        result = self.run_checked([self.java, '-cp', self.classpath,
                                  'dev.ullmann.lumo.ConnectFourRegression', name, str(self.work / name)])
        self.assertIn('CONNECT_FOUR_NATIVE_PASS ' + name, result.stdout)
        print(result.stdout.strip())


for _scenario in ('bridge-intents', 'invalid-intents', 'pending-terminal', 'authority',
                  'render-stall', 'pause-stale', 'stop-resume', 'closed-mailbox',
                  'bind-timeout', 'return-durable', 'return-write-failure', 'plugin-isolation'):
    setattr(ConnectFourNativeContractTest, 'test_' + _scenario.replace('-', '_'),
            lambda self, name=_scenario: self.scenario(name))

if __name__ == '__main__':
    unittest.main()
