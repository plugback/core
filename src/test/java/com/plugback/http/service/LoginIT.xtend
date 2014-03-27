package com.plugback.http.service

import com.codeborne.selenide.WebDriverRunner
import com.google.inject.servlet.ServletModule
import com.plugback.HttpRequest
import com.plugback.login.UserPasswordLoginModule
import java.net.URL
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.openqa.selenium.remote.DesiredCapabilities
import org.openqa.selenium.remote.RemoteWebDriver

import static com.plugback.TestConfig.*
import static org.junit.Assert.*

class LoginIT {

	RemoteWebDriver driver

	@Before
	def void initDriver() {

		usePhantomJS
	}

	@After
	def void tearDown() {
		driver.close
		driver.quit
	}

	def usePhantomJS() {
		val url = new URL("http://localhost:9090")
		val capabilities = DesiredCapabilities.phantomjs
		driver = new RemoteWebDriver(url, capabilities)
		WebDriverRunner.setWebDriver(driver)
	}

	@Test
	def void testLoginService() {

		val response = new HttpRequest(driver).getResponseAsString(
			ROOT + "loginService/login?user=romeo@gmail.com&password=ciao")
		assertEquals(response, '''{"errorCode":8432,"message":"Wrong username or password"}'''.toString)

		val response2 = new HttpRequest(driver).getResponseAsString(
			ROOT + "/loginService/login?email=romeo@plugback.com&password=123456")
		assertTrue(response2.contains('''{"email":"romeo@plugback.com"'''.toString))
		assertTrue(response2.contains('''lastTimeUpdated'''.toString))
		assertTrue(response2.contains('''creationDate'''.toString))
	}

}

class LoginTestModule extends ServletModule {

	override protected configureServlets() {
		install(
			new UserPasswordLoginModule().installOnPath("/loginService").setSuperAdmin("romeo@plugback.com", "123456")
		)
	}

}
