package com.plugback.http

import com.google.inject.servlet.ServletModule
import com.plugback.http.service.AsyncServant
import com.plugback.http.service.AsyncServantImpl
import com.plugback.http.service.DocumentCreator
import com.plugback.http.service.DocumentCreatorImpl
import com.plugback.http.service.DocumentProcessor
import com.plugback.http.service.DocumentProcessorImpl
import com.plugback.http.service.PagePath
import com.plugback.http.service.PagePathImpl
import com.plugback.http.service.RequestContextFactory
import com.plugback.http.service.RequestContextFactoryImpl
import com.plugback.persistence.PersistenceModule
import com.plugback.reflection.ReflectionHelperImpl
import com.plugback.reflection.ReflectionModule
import com.plugback.stream.StreamModule
import javax.inject.Singleton
import javax.servlet.http.HttpServlet

class HttpModule extends ServletModule {

	String[] paths

	IUploadManager uploadManager

	String uploadPath

	override protected configureServlets() {

		install(new ReflectionModule)
		install(new StreamModule)
		if(!shouldSkipPersistenceModuleInstallation)
			install(new PersistenceModule().inMemory)
		bind(RequestContextFactory).to(RequestContextFactoryImpl)

		bind(HttpMakeGetRequest).to(DefaultHttpMakeGetRequest)
		bind(PagePath).to(PagePathImpl)
		bind(DocumentCreator).to(DocumentCreatorImpl)
		bind(DocumentProcessor).to(DocumentProcessorImpl)
		bind(AsyncServant).to(AsyncServantImpl)

		if (uploadManager != null) {
			bind(IUploadManager).to(uploadManager.class)
			bind(UploadServlet).in(Singleton)
			serve(uploadPath).with(UploadServlet)
		}

		if (paths != null && paths.size > 0) {
			bind(StaticServlet).in(Singleton)
			paths.forEach [
				serve(it).with(StaticServlet)
			]
		}

		if (homePage != null) {
			bind(homePage).in(Singleton)
			serve("/").with(homePage)
		}

		if (pagesPaths.size > 0)
			pagesPaths.forEach [ path, servlet |
				bind(servlet).in(Singleton)
				serve(path).with(servlet)
			]
	}

	var Class<? extends HttpServlet> homePage

	def serveHomeWith(Class<? extends HttpServlet> homePage) {
		this.homePage = homePage
		return this
	}

	val pagesPaths = <String, Class<HttpServlet>>newHashMap
	
	boolean shouldSkipPersistenceModuleInstallation = false

	def servePagesInPackage(String packageName) {
		val extension reflection = new ReflectionHelperImpl
		val pages = packageName.getPackageConcreteClasses
		val pfpc = new PagePathImpl
		pages.filter[it.allInterfaces.contains(Page)].forEach [ p |
				val path = pfpc.getPath(p as Class<Page>)
				if (path != "/") {
					val pageClass = p as Class<HttpServlet>
					pagesPaths.put(path + "*", pageClass)
			}
		]
		return this
	}
	
	def HttpModule skipPersistenceModuleInstallation(){
		this.shouldSkipPersistenceModuleInstallation = true
		return this
	}

	def addUploadCapability(String uploadPath, IUploadManager uploadManager) {
		this.uploadPath = uploadPath
		this.uploadManager = uploadManager
		return this
	}

	def serveStaticContentMatching(String ... paths) {
		this.paths = paths
		return this
	}

}
