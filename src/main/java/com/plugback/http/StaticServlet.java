package com.plugback.http;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.util.zip.GZIPOutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.inject.Inject;
import com.google.inject.name.Named;

@SuppressWarnings("serial")
public class StaticServlet extends HttpServlet {

	public static final String CACHE_FILES = "CACHE_FILES";


	@Inject
	@Named(StaticServlet.CACHE_FILES)
	private boolean cacheFiles;

	public static interface LookupResult {
		public void respondGet(HttpServletResponse resp) throws IOException;

		public void respondHead(HttpServletResponse resp);

		public long getLastModified();
	}

	public static class Error implements LookupResult {
		protected final int statusCode;
		protected final String message;

		public Error(int statusCode, String message) {
			this.statusCode = statusCode;
			this.message = message;
		}

		public long getLastModified() {
			return -1;
		}

		public void respondGet(HttpServletResponse resp) throws IOException {
			resp.sendError(statusCode, message);
		}

		public void respondHead(HttpServletResponse resp) {
			throw new UnsupportedOperationException();
		}
	}

	public static class StaticFile implements LookupResult {
		protected final long lastModified;
		protected final String mimeType;
		protected final int contentLength;
		protected final boolean acceptsDeflate;
		protected final URL url;

		public StaticFile(long lastModified, String mimeType,
				int contentLength, boolean acceptsDeflate, URL url) {
			this.lastModified = lastModified;
			this.mimeType = mimeType;
			this.contentLength = contentLength;
			this.acceptsDeflate = acceptsDeflate;
			this.url = url;
		}

		public long getLastModified() {
			return lastModified;
		}

		protected boolean willDeflate() {
			return acceptsDeflate && deflatable(mimeType)
					&& contentLength >= deflateThreshold;
		}

		protected void setHeaders(HttpServletResponse resp) {
			resp.setStatus(HttpServletResponse.SC_OK);
			resp.setContentType(mimeType);
			if (contentLength >= 0 && !willDeflate())
				resp.setContentLength(contentLength);
		}

		public void respondGet(HttpServletResponse resp) throws IOException {
			setHeaders(resp);
			final OutputStream os;
			if (willDeflate()) {
				resp.setHeader("Content-Encoding", "gzip");
				os = new GZIPOutputStream(resp.getOutputStream(), bufferSize);
			} else
				os = resp.getOutputStream();
			transferStreams(url.openStream(), os);
		}

		public void respondHead(HttpServletResponse resp) {
			if (willDeflate())
				throw new UnsupportedOperationException();
			setHeaders(resp);
		}
	}

	@SafeVarargs
	public static <T> T coalesce(T... ts) {
		for (T t : ts)
			if (t != null)
				return t;
		return null;
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
		lookup(req).respondGet(resp);
	}

	@Override
	protected void doPut(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
		doGet(req, resp);
	}

	@Override
	protected void doHead(HttpServletRequest req, HttpServletResponse resp)
			throws IOException, ServletException {
		try {
			lookup(req).respondHead(resp);
		} catch (UnsupportedOperationException e) {
			super.doHead(req, resp);
		}
	}

	@Override
	protected long getLastModified(HttpServletRequest req) {
		return lookup(req).getLastModified();
	}

	protected LookupResult lookup(HttpServletRequest req) {
		if (!cacheFiles) {
			// logger.info("Debug mode, serving fresh file: " +
			// req.getPathInfo());
			return lookupNoCache(req);
		}
		// logger.info("Looking up for the request in cache: " +
		// req.getPathInfo());
		LookupResult r = (LookupResult) req.getAttribute("lookupResult");
		if (r == null) {
			// logger.info("Request not in cache");
			r = lookupNoCache(req);
			req.setAttribute("lookupResult", r);
		} else {
			// logger.info("Serving from cache: " + req.getPathInfo());
		}

		return r;
	}
	
	protected String removeBackSlashAtTheBeginning(String path)
	{
		if (path.startsWith("/") || path.startsWith("\\"))
			path = path.substring(1);
		return path;
	}
	

	protected LookupResult lookupNoCache(HttpServletRequest req) {
		final String path = req.getRequestURI().replace(req.getContextPath(),
				"");
		// logger.info("Loading resource from " + path);
		if (isForbidden(path)) {
			// logger.warning("This path cannot be served: forbidden because in web-inf or meta-inf folder:"
			// + path);
			return new Error(HttpServletResponse.SC_FORBIDDEN, "Forbidden");
		}

		
		ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
		URL url = classLoader .getResource(
				"/" + removeBackSlashAtTheBeginning(path.replace('\\', '/')));
		if (url == null)
			url = classLoader.getResource(
					removeBackSlashAtTheBeginning(path.replace('\\', '/')));
		
		if (url == null) {
			// logger.warning("This path cannot be served: not found" + path);
			return new Error(HttpServletResponse.SC_NOT_FOUND, "Not found");
		}

		final String mimeType = getMimeType(path);
		try {
			File f = new File(url.toURI());
			if (!f.isFile()) {
				// logger.warning("This path cannot be served: forbidden because it is not a file or it is not accessible:"
				// + path);
				return new Error(HttpServletResponse.SC_FORBIDDEN, "Forbidden");
			} else {
				// logger.info("Serving file" + path);
				return new StaticFile(f.lastModified(), mimeType,
						(int) f.length(), acceptsDeflate(req), url);
			}
		} catch (Exception e) {
			String message = "Cannot find this resource on server: " + path
					+ " (" + e.getMessage() + ")";
			// logger.severe(message);
			return new Error(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
					message);
		}
	}

	protected boolean isForbidden(String path) {
		String lpath = path.toLowerCase();
		return lpath.startsWith("/web-inf/") || lpath.startsWith("/meta-inf/");
	}

	protected String getMimeType(String path) {
		if (path.contains(".manifest"))
			return "text/cache-manifest";
		return coalesce(getServletContext().getMimeType(path),
				"application/octet-stream");
	}

	protected static boolean acceptsDeflate(HttpServletRequest req) {
		final String ae = req.getHeader("Accept-Encoding");
		return ae != null && ae.contains("gzip");
	}

	protected static boolean deflatable(String mimetype) {
		return mimetype.startsWith("text/")
				|| mimetype.equals("application/postscript")
				|| mimetype.startsWith("application/ms")
				|| mimetype.startsWith("application/vnd")
				|| mimetype.endsWith("xml");
	}

	protected static final int deflateThreshold = 4 * 1024;

	protected static final int bufferSize = 4 * 1024;

	protected static void transferStreams(InputStream is, OutputStream os)
			throws IOException {
		try {
			byte[] buf = new byte[bufferSize];
			int bytesRead;
			while ((bytesRead = is.read(buf)) != -1)
				os.write(buf, 0, bytesRead);
		} finally {
			is.close();
			os.close();
		}
	}
}
