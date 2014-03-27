package com.plugback.http.service

import com.plugback.active.interfaces.GenerateInterface
import com.plugback.http.Page
import com.plugback.http.service.annotations.Html
import com.plugback.http.service.annotations.Template
import com.plugback.stream.ILoader
import javax.inject.Inject
import org.jsoup.Jsoup
import org.jsoup.nodes.Document

import static extension com.plugback.stream.StreamExtension.*
import com.plugback.active.log.Loggable
import java.io.InputStream

@GenerateInterface
@Loggable
class DocumentCreatorImpl {

	@Inject
	ILoader loader

	override Document createDocument(Page page, RequestContext r) {
		var c = page.class
		if (c.simpleName.contains("$$"))
			c = c.superclass as Class<? extends Page>
		var Document doc
		var pathToHtml = c.simpleName + ".html";
		if (c.isAnnotationPresent(Html))
			pathToHtml = c.getAnnotation(Html).value
		var InputStream docStream = null
		try{
			docStream = loader.load(pathToHtml)
		}catch(Exception e){
			'''Loading file from classpath throwed an exception. 
			«e.message»'''.warn
		}
		if (docStream == null){
			'''Cannot find the html file «pathToHtml» specified in the class «c.name»'''.warn
			'''Building empty document'''.warn
		}

		var html = if(docStream != null) docStream.content else '''<html><head></head><body></body></html>'''
		doc = Jsoup.parse(html)

		if (c.isAnnotationPresent(Template)) {
			val pathToTemplate = c.getAnnotation(Template).value
			var stream = loader.load(pathToTemplate)
			if (stream == null)
				stream = loader.load(pathToTemplate.toLowerCase);

			if (stream == null)
				throw new IllegalArgumentException(
					"Cannot find the template " + pathToTemplate + "specified in the class " + c.name);
			val template = Jsoup.parse(stream.content)
			var content = doc.select("#content").first
			if (content == null)
				content = doc.select("body").first
			template.select("#content").html(content.html().toString())
			val templateHeadElement = template.select("head")
			templateHeadElement.select("title").remove()
			val templateHead = new StringBuilder(templateHeadElement.html())
			val htmlHeadElements = doc.select("head > *");
			val hi = htmlHeadElements.iterator();
			var ths = templateHead.toString();
			while (hi.hasNext()) {
				val element = hi.next();
				if (!ths.contains(element.toString()))
					templateHead.append(element.toString())
			}
			template.select("head").html(templateHead.toString())
			doc = template
		}
		return doc
	}

}
