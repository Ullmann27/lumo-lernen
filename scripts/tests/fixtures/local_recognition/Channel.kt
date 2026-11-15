package io.flutter.plugin.common

interface BinaryMessenger
class MethodCall(val method: String, val values: Map<String, Any?> = emptyMap()) {
    @Suppress("UNCHECKED_CAST") fun <T> argument(name: String): T? = values[name] as? T
}
class MethodChannel(messenger: BinaryMessenger, val name: String) {
    interface Result {
        fun success(value: Any?)
        fun error(code: String, message: String?, details: Any?)
        fun notImplemented()
    }
    interface MethodCallHandler { fun onMethodCall(call: MethodCall, result: Result) }
    var handler: MethodCallHandler? = null
    val events = mutableListOf<Pair<String, Any?>>()
    init { latest = this }
    fun setMethodCallHandler(value: MethodCallHandler?) { handler = value }
    fun invokeMethod(method: String, value: Any?) { events.add(method to value) }
    companion object { lateinit var latest: MethodChannel }
}
