package com.plugback;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Set;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.params.ClientPNames;
import org.apache.http.client.protocol.ClientContext;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.cookie.BasicClientCookie;
import org.apache.http.params.HttpParams;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.log4j.Logger;
import org.apache.log4j.lf5.util.StreamUtils;
import org.openqa.selenium.Cookie;
import org.openqa.selenium.WebDriver;

import com.plugback.stream.StreamExtension;

public class HttpRequest {

	private static final Logger LOG = Logger.getLogger(HttpRequest.class);
	private WebDriver driver;
	private String localDownloadPath = "";
	private boolean followRedirects = true;
	private boolean mimicWebDriverCookieState = true;
	private int httpStatusOfLastDownloadAttempt = 0;

	public HttpRequest(WebDriver driverObject) {
		this.driver = driverObject;
	}

	/**
	 * Specify if the FileDownloader class should follow redirects when trying
	 * to download a file
	 * 
	 * @param value
	 */
	public void followRedirectsWhenDownloading(boolean value) {
		this.followRedirects = value;
	}

	/**
	 * Get the current location that files will be downloaded to.
	 * 
	 * @return The filepath that the file will be downloaded to.
	 */
	public String localDownloadPath() {
		return this.localDownloadPath;
	}

	/**
	 * Set the path that files will be downloaded to.
	 * 
	 * @param filePath
	 *            The filepath that the file will be downloaded to.
	 */
	public void localDownloadPath(String filePath) {
		this.localDownloadPath = filePath;
	}

	/**
	 * Download the file specified in the href attribute of a WebElement
	 * 
	 * @param element
	 * @return
	 * @throws Exception
	 */
	public String downloadFile(String link) throws Exception {
		return downloader(link);
	}

	/**
	 * Download the image specified in the src attribute of a WebElement
	 * 
	 * @param element
	 * @return
	 * @throws Exception
	 */
	public String downloadImage(String link) throws Exception {
		return downloader(link);
	}

	/**
	 * Gets the HTTP status code of the last download file attempt
	 * 
	 * @return
	 */
	public int getHTTPStatusOfLastDownloadAttempt() {
		return this.httpStatusOfLastDownloadAttempt;
	}

	/**
	 * Mimic the cookie state of WebDriver (Defaults to true) This will enable
	 * you to access files that are only available when logged in. If set to
	 * false the connection will be made as an anonymouse user
	 * 
	 * @param value
	 */
	public void mimicWebDriverCookieState(boolean value) {
		this.mimicWebDriverCookieState = value;
	}

	/**
	 * Load in all the cookies WebDriver currently knows about so that we can
	 * mimic the browser cookie state
	 * 
	 * @param seleniumCookieSet
	 * @return
	 */
	private BasicCookieStore mimicCookieState(Set<Cookie> seleniumCookieSet) {
		BasicCookieStore mimicWebDriverCookieStore = new BasicCookieStore();
		for (Cookie seleniumCookie : seleniumCookieSet) {
			BasicClientCookie duplicateCookie = new BasicClientCookie(
					seleniumCookie.getName(), seleniumCookie.getValue());
			duplicateCookie.setDomain(seleniumCookie.getDomain());
			duplicateCookie.setSecure(seleniumCookie.isSecure());
			duplicateCookie.setExpiryDate(seleniumCookie.getExpiry());
			duplicateCookie.setPath(seleniumCookie.getPath());
			mimicWebDriverCookieStore.addCookie(duplicateCookie);
		}

		return mimicWebDriverCookieStore;
	}
	
	public String getResponseAsString(String link) throws IllegalStateException, IOException, URISyntaxException{
		HttpResponse response = getResponse(link);
		return StreamExtension.content(response.getEntity().getContent());
	}

	/**
	 * Perform the file/image download.
	 * 
	 * @param element
	 * @param attribute
	 * @return
	 * @throws IOException
	 * @throws NullPointerException
	 */
	private String downloader(String link) throws IOException, NullPointerException, URISyntaxException {
 
        HttpResponse response = getResponse(link);
        String contentDispositionValue = response.getFirstHeader("Content-Disposition").getValue();
        String filename = contentDispositionValue.substring(contentDispositionValue.lastIndexOf("filename=") + "filename=".length());
        
        File downloadedFile = new File(this.localDownloadPath + filename);
        if (downloadedFile.canWrite() == false) downloadedFile.setWritable(true);
        		
        LOG.info("HTTP GET request status: " + this.httpStatusOfLastDownloadAttempt);
        LOG.info("Downloading file: " + downloadedFile.getName());
        FileUtils.copyInputStreamToFile(response.getEntity().getContent(), downloadedFile);
        response.getEntity().getContent().close();
 
        String downloadedFileAbsolutePath = downloadedFile.getAbsolutePath();
        LOG.info("File downloaded to '" + downloadedFileAbsolutePath + "'");
 
        return downloadedFileAbsolutePath;
    }

	private HttpResponse getResponse(String link) throws MalformedURLException,
			URISyntaxException, IOException, ClientProtocolException {
		URL fileToDownload = new URL(link);
        
 
        HttpClient client = new DefaultHttpClient();
        BasicHttpContext localContext = new BasicHttpContext();
 
        LOG.info("Mimic WebDriver cookie state: " + this.mimicWebDriverCookieState);
        if (this.mimicWebDriverCookieState) {
            localContext.setAttribute(ClientContext.COOKIE_STORE, mimicCookieState(this.driver.manage().getCookies()));
        }
 
        HttpGet httpget = new HttpGet(fileToDownload.toURI());
        HttpParams httpRequestParameters = httpget.getParams();
        httpRequestParameters.setParameter(ClientPNames.HANDLE_REDIRECTS, this.followRedirects);
        httpget.setParams(httpRequestParameters);
 
        LOG.info("Sending GET request for: " + httpget.getURI());
        HttpResponse response = client.execute(httpget, localContext);
        this.httpStatusOfLastDownloadAttempt = response.getStatusLine().getStatusCode();
		return response;
	}
}