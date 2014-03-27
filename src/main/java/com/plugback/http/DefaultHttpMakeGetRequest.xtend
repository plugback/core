package com.plugback.http

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import com.plugback.active.interfaces.GenerateInterface

@GenerateInterface
class DefaultHttpMakeGetRequest {
	
	override String get(String url) {

		val obj = new URL(url)
		val con = obj.openConnection() as HttpURLConnection

		val responseCode = con.getResponseCode()
		if (responseCode != 200) {
			throw new IllegalStateException("Cannot make request. Response code was: " + responseCode)
		}

		val in = new BufferedReader(new InputStreamReader(con.getInputStream()))
		var String inputLine
		val response = new StringBuffer()

		while ((inputLine = in.readLine()) != null) {
			response.append(inputLine)
		}
		in.close()

		return response.toString
	}
}
