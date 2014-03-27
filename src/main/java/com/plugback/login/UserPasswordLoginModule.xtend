package com.plugback.login

import com.google.inject.servlet.ServletModule
import com.plugback.active.fields.CreateField
import com.plugback.error.Errors
import com.plugback.http.PageServlet
import com.plugback.http.service.RequestContext
import com.plugback.http.service.annotations.Service
import com.plugback.security.SecurityModule
import com.plugback.user.EmailUser
import com.plugback.user.SuperAdmin
import javax.inject.Singleton
import org.apache.shiro.SecurityUtils
import org.apache.shiro.authc.AuthenticationException
import org.apache.shiro.authc.UsernamePasswordToken

import static extension com.plugback.persistence.DBExtension.*
import com.plugback.http.HttpModule

class UserPasswordLoginModule extends ServletModule {

	SecurityModule securityModule = new SecurityModule
	
	String loginPath

	override protected configureServlets() {

		security.addAuthenticationStrategy [ u, p, db |
			if (u == email && p == password)
				return new SuperAdmin => [
					setEmail(this.email)
					setHashedPassword(password)
				]
		].addRoles(Roles.superadmin).toEach(SuperAdmin)

		if (pojoClasses != null)
			pojoClasses.forEach [ pojoClass |
				security.addAuthenticationStrategy [ u, p, db |
					val foundUsers = db.find(pojoClass).where[it.email = email]
					return foundUsers.resultList.filter[matchesPassword(password)].head
				]
			]
		
		install(new HttpModule)

		install(security)

		bind(LoginServlet).in(Singleton)
		serve(loginPath).with(LoginServlet)
	}

	@CreateField
	def UserPasswordLoginModule addUserTypes(Class<? extends EmailUser> ... pojoClasses) {
		return this
	}

	def getSecurity() {
		return securityModule
	}

	@CreateField
	def UserPasswordLoginModule setSuperAdmin(String email, String password) {
		return this
	}

	def UserPasswordLoginModule installOnPath(String loginPath) {
		this.loginPath = loginPath
		if(!loginPath.endsWith("*"))
			this.loginPath = loginPath + "*"
		return this
	}

}

class Roles {
	public static val superadmin = "pb_superadmin"
}

class LoginServlet extends PageServlet {

	@Service
	def login(String email, String password) {
		val u = SecurityUtils.subject

		if (!u.authenticated) {
			try {
				u.login(new UsernamePasswordToken(email, password))
				return u.principal
			} catch (AuthenticationException e) {
				return Errors.wrognCredentials
			}
		}
	}

	@Service
	def loginWithRedirect(String email, String password, String url, RequestContext r) {
		val u = SecurityUtils.subject

		if (!u.authenticated) {
			try {
				u.login(new UsernamePasswordToken(email, password))
				r.redirect(url)
			} catch (AuthenticationException e) {
				if (url.contains("?"))
					r.redirect(url + "&loginFailed=true")
				else
					r.redirect(url + "?loginFailed=true")
			}
		}
	}

}
