package com.plugback.http.service

import com.plugback.active.interfaces.GenerateInterface
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import org.jsoup.nodes.Document

@GenerateInterface
class DocumentProcessorImpl {
	
	override void process(Object target, Method m, RequestContext r, Document i) {
		val args = newLinkedList()
		val parameterTypes = m.getParameterTypes()
		if (parameterTypes.size() > 0) {
			if (parameterTypes.get(0) == i.class)
				args.add(i)
			if (parameterTypes.get(0) == RequestContext)
				args.add(r)
		}
		if (parameterTypes.size() > 1) {
			if (parameterTypes.get(1) == i.class)
				args.add(i)
			if (parameterTypes.get(1) == RequestContext)
				args.add(r)
		}
		try {
			val s = args.size
			m.invoke(target, args.toArray(newArrayOfSize(s)))
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		} catch (InvocationTargetException e) {
			e.printStackTrace();
		}
	}
	
}