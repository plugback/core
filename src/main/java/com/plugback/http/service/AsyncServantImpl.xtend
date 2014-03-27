package com.plugback.http.service

import com.plugback.active.interfaces.GenerateInterface
import com.plugback.http.Page
import com.plugback.http.service.annotations.Service
import com.plugback.reflection.ReflectionHelper
import java.lang.reflect.Method
import javax.inject.Inject

@GenerateInterface
class AsyncServantImpl {

	@Inject
	ReflectionHelper reflection;

	def private Boolean isWrapper(Class<?> type) {
		return #["String", "Long", "Boolean", "Double", "Integer"].contains(type.simpleName)
	}

	override void execute(Method m, RequestContext r, Page target) {
		val parameterNames = reflection.getParameterNames(m)
		val parameterTypes = m.getParameterTypes
		val values = <Object>newArrayOfSize(parameterNames.length)

		val serializer = m.getAnnotation(Service).value.newInstance

		parameterTypes.forEach [ type, index |
			val name = parameterNames.get(index)
			if (type == RequestContext)
				values.set(index, r)
			else if(type == String)
				values.set(index, r.getParameter(name))
			else if ((type.primitive || type.wrapper) && r.hasParameter(name)) {
				var Object v = r.getParameter(name)
				v = switch (type) {
					case type == Integer: Integer.parseInt(v as String)
					case type == int: Integer.parseInt(v as String)
					case type == Double: Integer.parseInt((v as String).replace(",", "."))
					case type == double: Integer.parseInt((v as String).replace(",", "."))
					case type == Long: Long.parseLong(v as String)
					case type == long: Long.parseLong(v as String)
					case type == Boolean: if((v as String) == "false") false else true
					case type == boolean: if((v as String) == "false") false else true
					case type == Float: Float.parseFloat(v as String)
					case type == float: Float.parseFloat(v as String)
				}
				values.set(index, v)
			}
			else{
				val o = serializer.deserialize(r.json, type)
				values.set(index, o)
			}
		]
		if (m.returnType == String) {

			val data = m.invoke(target, values) as String
			if (data != null)
				if (data.startsWith("{") || data.startsWith("["))
					r.getResponse().setContentType("application/json")
			r.print(data)
		} else if (!m.getReturnType().equals(Void)) {
			val ret = m.invoke(target, values);
			if (ret == null)
				r.print("")
			else {
				var json = ""
				if (ret instanceof Iterable<?>) {
					val c = ret as Iterable<?>
					json = "[" + c.map[serializer.serialize(it)].join(",") + "]"

				} else {
					json = serializer.serialize(ret)
				}

				r.getResponse().setContentType("application/json; charset=UTF-8")
				r.print(json)
			}
		} else {
			m.invoke(target, values)
		}
	}

}
