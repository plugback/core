package com.plugback.log

import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.core.filter.Filter
import ch.qos.logback.core.spi.FilterReply
import com.google.inject.AbstractModule

class LogModule extends AbstractModule{
	
	public static String filteredPackage = ""
	
	def logClassesIntoPackage(String pkg){
		filteredPackage = pkg
		return this
	}
	
	override protected configure() {
		
	}
	
}

class LogFilter extends Filter<ILoggingEvent> {

	
	
	override FilterReply decide(ILoggingEvent event) {
		if (event.loggerName.startsWith(LogModule.filteredPackage)) {
			return FilterReply.ACCEPT
		} else {
			return FilterReply.DENY
		}
	}
	
}