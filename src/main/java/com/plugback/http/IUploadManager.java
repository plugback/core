package com.plugback.http;

import java.io.InputStream;

public interface IUploadManager {
	/**
	 * 
	 * @param name
	 *            a filename that can be used fo the id
	 * @param stream
	 * @param size
	 * @return the id of the file for future reference when loading it
	 */
	public String save(String name, InputStream stream, long size);
}
