package android.content

class Intent(val action: String) {
    val extras = mutableMapOf<String, Any?>()
    fun putExtra(key: String, value: Any?): Intent { extras[key] = value; return this }
}
