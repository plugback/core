package com.plugback.http.service

import com.plugback.active.interfaces.GenerateInterface
import com.plugback.http.service.annotations.Path

@GenerateInterface
class PagePathImpl {

	override String getPath(Class<?> p) {
		var c = p
		while (p.simpleName.toLowerCase().contains("$$"))
			c = p.superclass
		var path = if(c.isAnnotationPresent(Path)) 
						c.getAnnotation(Path).value 
					else 
						p.simpleName.toLowerCase
		if (path.contains("$$"))
			path = path.substring(0, path.indexOf("$$"))
		var fp = "/" + path
		if (fp.equals("//"))
			fp = "/"
		return fp
	}

}
