package com.plugback.reflection

import com.google.inject.AbstractModule

class ReflectionModule extends AbstractModule{
	
	override protected configure() {
		bind(ReflectionHelper).to(ReflectionHelperImpl)
	}
	
}