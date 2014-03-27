package com.plugback.config

import com.google.inject.Guice
import com.google.inject.servlet.GuiceServletContextListener
import com.google.inject.servlet.ServletModule
import com.plugback.http.PageServlet
import com.plugback.http.service.RequestContext
import com.plugback.http.HttpModule
import com.google.inject.Module

class GuiceConfig extends GuiceServletContextListener {

	override protected getInjector() {
		return Guice.createInjector(new AppModule)
	}
	
}

class AppModule extends ServletModule {

	override protected configureServlets() {
		
		val profile = System.getProperty("module")
		if(profile != null){
			val module = this.class.classLoader.loadClass(profile).newInstance as Module
			install(module)
		}
		else
			install(new HttpModule().serveHomeWith(Home))
	}
	
	
	
}


class Home extends PageServlet{
	
	override handle(RequestContext r) {
		$("head").html("<title>ciao v1</title>")
	}
	
}