package com.plugback.stream

import java.io.InputStream
import java.util.Scanner

class StreamExtension {

	def static String content(InputStream stream) {
		val scanner = new Scanner(stream)
		val content = scanner.useDelimiter("\\A").next()
		scanner.close()
		return new String(content.getBytes(), "UTF-8")
	}

}
