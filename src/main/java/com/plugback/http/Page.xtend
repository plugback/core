package com.plugback.http

import com.plugback.http.service.RequestContext
import javax.persistence.EntityManager
import org.jsoup.select.Elements

interface Page {

	def void handle(RequestContext r)

	def Elements $(String selector)

	def EntityManager db()

}
