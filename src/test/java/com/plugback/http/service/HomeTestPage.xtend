package com.plugback.http.service

import com.plugback.http.PageServlet
import com.plugback.http.service.annotations.Service

class HomeTestPage extends PageServlet{
	
	@Service
	def ok(String ciao){
		return ciao.toUpperCase
	}
	
}