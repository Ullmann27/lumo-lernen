package org.json
class JSONObject(text:String="{}") {
 private val data=linkedMapOf<String,Any?>()
 init { val regex=Regex("\"([^\"]+)\"\\s*:\\s*(\"[^\"]*\"|true|false|-?[0-9]+(?:\\.[0-9]+)?)");for(m in regex.findAll(text)){val v=m.groupValues[2];data[m.groupValues[1]]=when{v.startsWith("\"")->v.substring(1,v.length-1);v=="true"->true;v=="false"->false;v.contains('.') -> v.toDouble();else->v.toInt()}} }
 fun optString(key:String,fallback:String="")=data[key] as? String ?:fallback
 fun optInt(key:String,fallback:Int=0)=(data[key] as? Number)?.toInt()?:fallback
 fun optDouble(key:String,fallback:Double=0.0)=(data[key] as? Number)?.toDouble()?:fallback
 fun optBoolean(key:String,fallback:Boolean=false)=data[key] as? Boolean ?:fallback
 fun put(key:String,value:Any?):JSONObject {data[key]=value;return this}
 override fun toString()=data.entries.joinToString(",","{","}"){"\"${it.key}\":"+if(it.value is String)"\"${it.value}\"" else it.value.toString()}
}
