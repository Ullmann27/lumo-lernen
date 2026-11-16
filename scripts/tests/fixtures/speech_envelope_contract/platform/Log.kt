package android.util
object Log {
 val entries=mutableListOf<Pair<String,String>>()
 fun i(tag:String,message:String):Int {entries.add(tag to message);return 0}
}
