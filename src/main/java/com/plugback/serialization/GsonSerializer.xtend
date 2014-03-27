package com.plugback.serialization

import com.google.gson.Gson

class GsonSerializer implements Serializer{
	
	private Gson gson = new Gson
	
	override <T> serialize(T object) {
		return gson.toJson(object)
	}
	
	override <T> deserialize(String data, Class<T> c) {
		return gson.fromJson(data, c)
	}
	
}