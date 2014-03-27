import java.io.IOException;

public class StartPhantomJS {

	public static void main(String[] args) throws IOException {
		String port = "9090";
		if(System.getProperty("phantom.port") != null)
			port = System.getProperty("phantom.port");
		String phantom = args[0];
		if(phantom.equals("stop")){
			Runtime rt = Runtime.getRuntime();
			  if (System.getProperty("os.name").toLowerCase().indexOf("windows") > -1) 
			     rt.exec("taskkill /F /IM phantomjs.exe");
			   else
			     rt.exec("ps aux | grep -ie phantomjs | awk '{print $2}' | xargs kill -9 ");
		}
		else{
			Runtime.getRuntime().exec(phantom + " --webdriver=" + port);
		}
			
	}

}
