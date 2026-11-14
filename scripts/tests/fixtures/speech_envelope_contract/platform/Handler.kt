package android.os
class Looper { companion object { private val main=Looper();fun getMainLooper()=main } }
class Handler(looper:Looper) {
 fun post(task:Runnable):Boolean { synchronized(immediate){immediate.add(task)};return true }
 fun postDelayed(task:Runnable,delay:Long):Boolean { synchronized(delayed){delayed.add(task)};return true }
 fun removeCallbacks(task:Runnable) { synchronized(immediate){immediate.removeAll{it===task}};synchronized(delayed){delayed.removeAll{it===task}} }
 companion object {
  private val immediate=mutableListOf<Runnable>();private val delayed=mutableListOf<Runnable>()
  fun pending():Int=synchronized(immediate){immediate.size}
  fun drain() { var count=0;while(true){val next=synchronized(immediate){if(immediate.isEmpty())null else immediate.removeAt(0)}?:break;check(++count<1000);next.run()} }
  fun advance(){val jobs=synchronized(delayed){val copy=delayed.toList();delayed.clear();copy};synchronized(immediate){immediate.addAll(jobs)};drain()}
 }
}
