package com.plugback.security

import com.google.gson.Gson
import com.google.inject.Provides
import com.google.inject.servlet.ServletModule
import java.lang.reflect.Constructor
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton
import javax.persistence.EntityManager
import javax.servlet.ServletContext
import org.apache.shiro.authc.AuthenticationException
import org.apache.shiro.authc.AuthenticationToken
import org.apache.shiro.authc.SimpleAuthenticationInfo
import org.apache.shiro.authc.UsernamePasswordToken
import org.apache.shiro.authz.SimpleAuthorizationInfo
import org.apache.shiro.guice.aop.ShiroAopModule
import org.apache.shiro.guice.web.ShiroWebModule
import org.apache.shiro.io.SerializationException
import org.apache.shiro.io.Serializer
import org.apache.shiro.mgt.RememberMeManager
import org.apache.shiro.realm.AuthorizingRealm
import org.apache.shiro.subject.PrincipalCollection
import org.apache.shiro.web.mgt.CookieRememberMeManager
import org.apache.shiro.subject.SimplePrincipalCollection

class SecurityModule extends ServletModule {

	override protected configureServlets() {
		
		configureSecurity()

		val rc = new RealmConfiguration
		rc.rolesRules = rolesConfigurations
		rc.authenticationConfigurations = authenticationConfigurations

		bind(RealmConfiguration).toInstance(rc)

		install(new InternalSecurityModule(servletContext))
		install(new ShiroAopModule)

		install(ShiroWebModule.guiceFilterModule())
	}
	
	def void configureSecurity(){}

	@Provides
	@Singleton
	def RememberMeManager provideRememberMeManager() {
		val cm = new CookieRememberMeManager
		cm.setSerializer(new PrincipalCollectionSerializer)
		return cm
	}

	/**
	 * Create an authentication strategy that adds the returned object into the session.
	 * 
	 * @param userFinderGivenUsernamePasswordAndDB a function that returns the object 
	 * 										identifying the authenticated user. 
	 * 										<br>Ex.:
	 * 										<code>
	 * 											<br>[username, password, db |
	 *											<br>&nbsp;val pojo = db.createQuery("SELECT d FROM Doctor d WHERE d.email = ?1", YourPojo)
	 *											<br>&nbsp;&nbsp;&nbsp;.setParameter("1", username).singleResult
	 *											<br>&nbsp;pojo.checkPassword(password)
	 *											<br>&nbsp;return pojo
	 *										<br>]
	 * 										</code>
	 * 
	 */
	def addAuthenticationStrategy((String, String, EntityManager)=>Object userFinderGivenUsernamePasswordAndDB) {
		authenticationConfigurations.add(userFinderGivenUsernamePasswordAndDB)
		return this
	}

	/**
	 * Construct a role strategy.
	 * 
	 * @roles A list of strings rapresentig the roles
	 * 
	 * This method has a fluent API: 
	 * <br>you can specify a condition using the <code>when</code> following method 
	 * <br>or
	 * <br>you can assign the specified roles to each instance of a class using the 
	 * <br><code>toEach</code> following method 
	 * 
	 */
	def addRoles(String... roles) {
		return new WhenClause(this, roles)
	}

	val rolesConfigurations = new ConcurrentHashMap<(Object)=>Boolean, List<String>>

	package def addRoleConfiguration((Object)=>Boolean condition, String[] roles) {
		rolesConfigurations.put(condition, roles)
		return this
	}

	val authenticationConfigurations = <(String, String, EntityManager)=>Object>newArrayList

}

class InternalSecurityModule extends ShiroWebModule {

	new(ServletContext servletContext) {
		super(servletContext)
	}

	override protected configureShiroWeb() {
		val securityRealmConstructor = ShiroRealm.constructors.head as Constructor<ShiroRealm>
		bindRealm().toConstructor(securityRealmConstructor)
	}

}

class ShiroRealm extends AuthorizingRealm {

	@Inject
	Provider<EntityManager> em

	@Inject
	RealmConfiguration rc

	override protected doGetAuthorizationInfo(PrincipalCollection principals) {
		val ai = new SimpleAuthorizationInfo
		val target = principals.primaryPrincipal
		rc.rolesRules.forEach [ condition, roles |
			if (condition.apply(target))
				ai.addRoles(roles)
		]
		return ai
	}

	override protected doGetAuthenticationInfo(AuthenticationToken token) throws AuthenticationException {
		if (token instanceof UsernamePasswordToken) {
			val pwd = new String(token.password)

			for (ast : rc.authenticationConfigurations) {
				val tf = ast.apply(token.username, pwd, db)
				if (tf != null) {
					return new SimpleAuthenticationInfo(tf, token.password, ShiroRealm.simpleName)
				}
			}

			return null

		}
	}

	def db() {
		return em.get
	}

}

class RealmConfiguration {
	@Property Map<(Object)=>Boolean, List<String>> rolesRules

	@Property Collection<(String, String, EntityManager)=>Object> authenticationConfigurations
}

class WhenClause {

	SecurityModule module

	String[] roles

	new(SecurityModule module, String[] roles) {
		this.module = module
		this.roles = roles
	}

	def when((Object)=>Boolean condition) {
		module.addRoleConfiguration(condition, roles)
	}

	def <T> toEach(Class<T> t) {
		val condition = [Object o|o.class.name == t.name]
		module.addRoleConfiguration(condition, roles)
	}

}

class PrincipalCollectionSerializer implements Serializer<PrincipalCollection> {

	val gson = new Gson

	override deserialize(byte[] bytes) throws SerializationException {
		gson.fromJson(new String(bytes, "UTF-8"), SimplePrincipalCollection)
	}

	override serialize(PrincipalCollection object) throws SerializationException {
		gson.toJson(object).getBytes("UTF-8")
	}

}
