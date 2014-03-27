package com.plugback.serialization

import com.google.gson.ExclusionStrategy
import com.google.gson.FieldAttributes

class ExcludeFields implements ExclusionStrategy {
	
	String[] fields
	
	new(String... fields){
		this.fields = fields
	}
	
	override shouldSkipClass(Class<?> clazz) {
		return false
	}
	
	override shouldSkipField(FieldAttributes f) {
		val fieldName = f.name
		val contains = if(fields != null) fields.contains(fieldName) else false
		return contains
	}
	
}