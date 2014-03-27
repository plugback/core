package com.plugback.persistence

import com.google.inject.persist.PersistFilter
import com.google.inject.persist.jpa.JpaPersistModule
import com.google.inject.servlet.ServletModule
import javax.inject.Singleton
import java.util.Properties

class PersistenceModule extends ServletModule{
	
	boolean installInMemoryDB = false
	
	boolean installUsingDerbyLocally = false
	
	Properties p
	
	override protected configureServlets() {
		if(installInMemoryDB)
			install(new JpaPersistModule("in-memory"))
		else if(installUsingDerbyLocally)
			install(new JpaPersistModule("local-derby"))
		else
		{
			if(p.getProperty("javax.persistence.jdbc.driver") == null)
				throw new IllegalStateException("You forget to initialize the module with one of his methods: inMemory, usingDerbyOnLocalMachine or withParameters")
			install(new JpaPersistModule("model").properties(p))
		}	
		bind(PersistFilter).in(Singleton)
		filter("/*").through(PersistFilter)
	}
	
	def inMemory(){
		installInMemoryDB = true
		return this
	}
	
	def usingDerbyOnLocalMachine(){
		installUsingDerbyLocally = true
		return this
	}
	
	def withParameters(Class<?> driver, String url){
		p = new Properties
		p.put("javax.persistence.jdbc.driver", driver.name)
		p.put("javax.persistence.jdbc.url", url)
		return this
	}
	
	def withParameters(Class<?> driver, String url, String username, String password){
		withParameters(driver, url)
		p.put("javax.persistence.jdbc.user", username)
		p.put("javax.persistence.jdbc.password", password)
		return this
	}
	
}