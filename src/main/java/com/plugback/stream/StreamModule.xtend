package com.plugback.stream

import com.google.inject.AbstractModule

class StreamModule extends AbstractModule{
	
	override protected configure() {
		bind(ILoader).to(FromClassPathLoader)
	}
	
}