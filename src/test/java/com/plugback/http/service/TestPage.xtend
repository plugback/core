package com.plugback.http.service

import com.google.inject.Guice
import com.google.inject.Injector
import com.google.inject.Provider
import com.plugback.http.HttpModule
import com.plugback.utils.persistence.InMemoryEntityManager
import java.io.PrintWriter
import java.io.StringWriter
import javax.persistence.EntityManager
import javax.servlet.ServletContext
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import javax.servlet.http.HttpSession
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.runners.MockitoJUnitRunner

import static org.junit.Assert.*
import static org.mockito.Mockito.*

@RunWith(MockitoJUnitRunner)
class TestPage {

	Injector injector
	StringWriter sw
	PrintWriter out
	@Mock HttpServletRequest req
	@Mock HttpServletResponse resp
	@Mock Provider<EntityManager> em

	EntityManager db

	@Before
	def void initGuice() {
		injector = Guice.createInjector(
			[
				bind(EntityManager).toProvider(em)
			], new HttpModule().servePagesInPackage("com.plugback.http.service").skipPersistenceModuleInstallation)

		sw = new StringWriter
		out = new PrintWriter(sw)
		when(resp.getWriter()).thenReturn(out)
		val s = mock(HttpSession)
		when(s.servletContext).thenReturn(mock(ServletContext))
		when(req.session).thenReturn(s)

		when(req.contextPath).thenReturn("http://localhost:8085/")

		db = new InMemoryEntityManager
		when(em.get).thenReturn(db)
	}

	@Test
	def void testPageCreation() {
		when(req.requestURI).thenReturn("http://localhost:8085/" + "hometestpage")
		val page = injector.getInstance(HomeTestPage)
		page.doGet(req, resp)
		out.flush()
		val html = sw.toString
		assertTrue(html.contains('''<div id="content"></div>'''))
		assertTrue(html.contains('''<!DOCTYPE html>'''))
		assertTrue(html.contains('''<title>Page title</title> '''))
	}

	@Test
	def void testPageService() {
		when(req.requestURI).thenReturn("http://localhost:8085/" + "hometestpage/ok?ciao=ciaociao")
		when(req.getParameter("ciao")).thenReturn("ciaociao")
		val page = injector.getInstance(HomeTestPage)
		page.doGet(req, resp)
		out.flush()
		assertEquals(sw.toString, "CIAOCIAO")
		sw = new StringWriter
		out = new PrintWriter(sw)
	}

}
