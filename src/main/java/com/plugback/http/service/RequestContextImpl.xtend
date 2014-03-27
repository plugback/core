package com.plugback.http.service

import com.plugback.active.interfaces.GenerateInterface
import com.plugback.active.properties.ReadOnly
import com.plugback.active.properties.ReadOnlyConstructor
import javax.servlet.ServletContext
import javax.servlet.http.Cookie
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import javax.servlet.http.HttpSession

@GenerateInterface
@ReadOnlyConstructor
class RequestContextImpl {

	val ONE_MONTH = 30 * 24 * 60 * 60
	val COOKIE_PATH = "/"

	@ReadOnly HttpServletRequest request
	@ReadOnly HttpServletResponse response

	override HttpServletRequest getRequest() {
		return request
	}

	override HttpServletResponse getResponse() {
		return response
	}

	override ServletContext getServletContext() {
		return request.session.servletContext
	}

	override String getPath() {
		val path = request.requestURI.replace(request.contextPath, "")
		return path.toLowerCase
	}

	override String getFullUrl() {
		val requestURL = request.requestURL
		request.queryString ?: requestURL.append("?").append(request.queryString);
		return requestURL.toString.toLowerCase
	}

	override HttpSession getSession() {
		return request.session
	}

	override void print(String message) {
		response.writer.print(message)
	}

	override void redirect(String url) {
		response.sendRedirect(url)
	}

	override String getLocale() {
		return request.locale.language.toLowerCase
	}

	override String getIP() {
		return request.remoteAddr
	}

	override String getParameter(String parameterName) {
		return request.getParameter(parameterName)
	}

	override Boolean hasParameter(String parameterName) {
		return getParameter(parameterName) != null && getParameter(parameterName) != ""
	}

	override String getCookie(String key) {
		request.cookies.filter[name == key].head.value
	}

	override void saveCookie(String key, String value) {
		val c = new Cookie(key, value)
		c.setMaxAge(ONE_MONTH)
		c.setPath(COOKIE_PATH)
		response.addCookie(c)
	}

	override String getUrlRoot() {
		return request.requestURL.toString().replace(request.requestURI, "")
	}
	
	private String body = ""
	
	override String getJson(){
		if(body != "")
			return body
		var stringBuilder = new StringBuilder

		val inputStream = request.reader
		if (inputStream != null) {
			var charBuffer = newCharArrayOfSize(128)
			var bytesRead = -1;
			while ((bytesRead = inputStream.read(charBuffer)) > 0) {
				stringBuilder.append(charBuffer, 0, bytesRead)
			}
		} else {
			stringBuilder.append("");
		}
		inputStream.close

		body = stringBuilder.toString
		return body
	}

}
