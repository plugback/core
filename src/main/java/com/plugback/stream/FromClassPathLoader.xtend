package com.plugback.stream

import com.plugback.active.interfaces.GenerateInterface
import java.io.InputStream

@GenerateInterface("ILoader")
class FromClassPathLoader {
	
	override InputStream load(String path) {
		var res = this.class.getResourceAsStream(
				"/" + removeBackSlashAtTheBeginning(swapBackSlash(path)));
		if (res == null)
			res = this.class.getResourceAsStream(
				"/" + removeBackSlashAtTheBeginning(swapBackSlash(path).toLowerCase));
		if (res == null)
			res = this.class.classLoader.getResourceAsStream(
					removeBackSlashAtTheBeginning(swapBackSlash(path)));
		if (res == null)
			res = this.class.classLoader.getResourceAsStream(
					removeBackSlashAtTheBeginning(swapBackSlash(path).toLowerCase));
		if (res == null)
			throw new IllegalArgumentException("Cannot find file: " + path);
		return res;
	}
	
	def protected String removeBackSlashAtTheBeginning(String path)
	{
		var p = path
		if (path.startsWith("/") || path.startsWith("\\"))
			p = path.substring(1)
		return p
	}
	
	def protected String swapBackSlash(String path)
	{
		return path.replace('\\', '/');
	}
	
}