package android.os

object Build {
    object VERSION { var SDK_INT = 36 }
    object VERSION_CODES { const val S = 31; const val M = 23 }
}

class Bundle {
    val values = mutableMapOf<String, Any>()
    @Suppress("UNCHECKED_CAST")
    fun getStringArrayList(key: String): ArrayList<String>? = values[key] as? ArrayList<String>
    fun getFloatArray(key: String): FloatArray? = values[key] as? FloatArray
}

class Looper { companion object { fun getMainLooper() = Looper() } }

class Handler(looper: Looper) {
    fun post(work: Runnable): Boolean { work.run(); return true }
    fun postDelayed(work: Runnable, delay: Long): Boolean { delayed.add(work); return true }
    fun removeCallbacks(work: Runnable) { delayed.remove(work) }
    companion object {
        private val delayed = mutableListOf<Runnable>()
        fun advanceDeadlines() {
            val waiting = delayed.toList()
            delayed.clear()
            waiting.forEach { it.run() }
        }
    }
}
