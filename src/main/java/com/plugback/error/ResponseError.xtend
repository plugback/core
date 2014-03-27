package com.plugback.error

import com.plugback.active.fields.Data

@Data
class ResponseError {

	new(Integer errorCode, String message) {
	}

}

class Errors {
	public static val wrognCredentials = new ResponseError(8432, "Wrong username or password")
}
