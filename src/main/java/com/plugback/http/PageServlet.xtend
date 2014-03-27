package com.plugback.http

import com.google.inject.Provider
import com.plugback.http.service.DocumentCreator
import com.plugback.http.service.DocumentProcessor
import com.plugback.http.service.PagePath
import com.plugback.http.service.RequestContext
import com.plugback.http.service.RequestContextFactory
import com.plugback.http.service.annotations.AfterHandling
import com.plugback.http.service.annotations.BeforeHandling
import com.plugback.http.service.annotations.Service
import com.plugback.reflection.ReflectionHelper
import java.lang.reflect.Method
import java.util.regex.Pattern
import javax.inject.Inject
import javax.persistence.EntityManager
import javax.servlet.http.HttpServlet
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import org.jsoup.nodes.Document
import com.plugback.http.service.AsyncServant

class PageServlet extends HttpServlet implements Page {

	@Inject RequestContextFactory requestContextFactory
	@Inject Provider<EntityManager> em
	@Inject extension ReflectionHelper reflection
	@Inject extension PagePath pathFinder
	@Inject extension DocumentCreator documentCreator
	@Inject extension DocumentProcessor documentProcessor
	@Inject AsyncServant asyncServant

	val document = new ThreadLocal<Document>
	val databaseContainer = new ThreadLocal<EntityManager>

	override doGet(HttpServletRequest req, HttpServletResponse resp) {
		serve(req, resp);
	}

	override doPost(HttpServletRequest req, HttpServletResponse resp) {
		serve(req, resp);
	}

	override doDelete(HttpServletRequest req, HttpServletResponse resp) {
		serve(req, resp);
	}

	override doPut(HttpServletRequest req, HttpServletResponse resp) {
		serve(req, resp);
	}

	def serve(HttpServletRequest req, HttpServletResponse resp) {
		val r = requestContextFactory.createContext(req, resp);

		initDatabase()

		var async = serveAsync(r)

		if (!async) {
			serveDocument(r)
		}

		databaseContainer.set(null)
	}

	def initDatabase() {
		databaseContainer.set(em.get)
	}

	def serveDocument(RequestContext r) {
		val doc = createDocument(r)
		document.set(doc)

		r.getResponse().setContentType("text/html");
		r.getResponse().setCharacterEncoding("UTF-8");

		val numberOfSlashes = r.path.replaceAll("[^/]", "").length();
		if (numberOfSlashes > 1) {
			normalizeLinks(doc, "a", "href", r.getUrlRoot());
			normalizeLinks(doc, "link", "href", r.getUrlRoot());
			normalizeLinks(doc, "img", "src", r.getUrlRoot());
			normalizeLinks(doc, "script", "src", r.getUrlRoot());
		}
		val methodsMarkedBeforeHandling = this.class.allMethods.filter[isAnnotationPresent(BeforeHandling)]
		if (methodsMarkedBeforeHandling.size > 0)
			methodsMarkedBeforeHandling.forEach[documentProcessor.process(this, it, r, doc)]

		handle(r)

		val methodsMarkedAfterHandling = this.class.allMethods.filter[isAnnotationPresent(AfterHandling)]
		if (methodsMarkedAfterHandling.size > 0)
			methodsMarkedAfterHandling.forEach[documentProcessor.process(this, it, r, doc)]

		var html = doc.toString
		document.remove
		r.print(html)

	}

	val Pattern afterPathPattern = Pattern.compile("(/*[^/^\\?]+)([/\\?]*.*)");

	def serveAsync(RequestContext r) {

		var async = false;

		val pagePath = this.class.path
		val requestPath = r.path
		var pathWithParameters = r.path
		if (r.request.queryString != null)
			pathWithParameters = pathWithParameters + "?" + r.request.queryString
		val matcher = afterPathPattern.matcher(r.path)
		var requestPathPrefix = requestPath;
		var requestPathPostfix = "";
		if (matcher.matches()) {
			requestPathPrefix = matcher.group(1);
			requestPathPostfix = matcher.group(2);
		}
		if (pagePath == "/")
			requestPathPostfix = requestPathPrefix

		if (requestPath.length() > pagePath.length() + 1) {
			if (requestPathPostfix.length() > 2) {
				var possibleAsyncServicePath = requestPathPostfix.substring(1);
				if (possibleAsyncServicePath.contains("?"))
					possibleAsyncServicePath = possibleAsyncServicePath.substring(0,
						possibleAsyncServicePath.indexOf('?'));
				if (possibleAsyncServicePath.contains("/"))
					possibleAsyncServicePath = possibleAsyncServicePath.substring(0,
						possibleAsyncServicePath.indexOf('/'));
				val methodsMarkedAsService = this.class.methods.filter[isAnnotationPresent(Service)]
				val ps = possibleAsyncServicePath
				var isServiceCall = methodsMarkedAsService.map[it.name.toLowerCase].filter[it == ps].size > 0
				if (isServiceCall) {
					async = true;
					serveAsyncService(methodsMarkedAsService.filter[name.toLowerCase == ps].head, r);
				}
			}
		}

		return async
	}

	def serveAsyncService(Method m, RequestContext r) {
		asyncServant.execute(m, r, this)
	}

	override handle(RequestContext r) {
	}

	override $(String selector) {
		return document.get().select(selector)
	}

	override db() {
		return databaseContainer.get
	}

	private def normalizeLinks(Document doc, String selector, String attributeKey, String urlRoot) {
		val links = doc.select(selector).iterator();
		while (links.hasNext()) {
			val e = links.next();
			if (e.hasAttr(attributeKey)) {
				val attr = e.attr(attributeKey);
				if (!attr.startsWith("#")) {
					if (!attr.startsWith("/")) {
						if (!(attr.startsWith("http") || attr.startsWith("ftp") || attr.startsWith("tel") ||
							attr.startsWith("skype") || attr.startsWith("mailto")))
							e.attr(attributeKey, urlRoot + "/" + attr);
					}
				}
			}
		}
	}

}
