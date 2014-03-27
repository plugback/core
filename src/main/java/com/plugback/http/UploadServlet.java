package com.plugback.http;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.List;

import javax.inject.Inject;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileItemFactory;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import com.plugback.http.service.RequestContext;
import com.plugback.http.service.RequestContextFactory;

public class UploadServlet extends HttpServlet {
	private static final long serialVersionUID = -4687469266995384745L;

	@Inject
	private IUploadManager fileManager;

	@Inject
	private RequestContextFactory rf;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		RequestContext r = rf.createContext(req, resp);
		upload(r);
	}

	@Override
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		RequestContext r = rf.createContext(request, response);
		upload(r);
	}

	private void upload(RequestContext r) throws IOException {
		PrintWriter out = r.getResponse().getWriter();

		boolean isMultipart = ServletFileUpload.isMultipartContent(r
				.getRequest());
		if (!isMultipart) {
			out.print("Errore: questo servizio puo' essere richiamato solo per fare l'upload dei file");
			return;
		}

		FileItemFactory factory = new DiskFileItemFactory();
		ServletFileUpload upload = new ServletFileUpload(factory);

		String fileId = "";
		try {
			List<?> items = upload.parseRequest(r.getRequest());
			for (Object o : items) {
				FileItem item = (FileItem) o;
				String name = item.getName();
				InputStream stream = item.getInputStream();
				fileId = manageFile(name, stream, item.getSize());
				stream.close();
			}
		} catch (FileUploadException e) {
			e.printStackTrace();
		}

		out.print(fileId);
	}

	private String manageFile(String name, InputStream stream, long size) {
		return fileManager.save(name, stream, size);
	}

}
