package com.plugback.http.service

import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse

interface RequestContextFactory {
	
	def RequestContext createContext(HttpServletRequest request, HttpServletResponse response)
	
}

class RequestContextFactoryImpl implements RequestContextFactory{
	
	override createContext(HttpServletRequest request, HttpServletResponse response) {
		return new RequestContextImpl(request, response)
	}
	
}