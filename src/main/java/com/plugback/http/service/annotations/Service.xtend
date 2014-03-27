package com.plugback.http.service.annotations

import com.plugback.serialization.JsonExcludingHashedPasswordSerializer
import com.plugback.serialization.Serializer
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
annotation Service {
	Class<? extends Serializer> value = JsonExcludingHashedPasswordSerializer
}
