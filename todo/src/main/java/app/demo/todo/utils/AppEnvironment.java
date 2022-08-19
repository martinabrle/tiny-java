package app.demo.todo.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AppEnvironment {
	public static final Logger LOGGER = LoggerFactory.getLogger(AppEnvironment.class);

	public static String GetCurrentDirectory() {
		String currentPath = "";

		try {
			currentPath = new java.io.File(".").getCanonicalPath();
			LOGGER.info(String.format("Current dir: '%s'", currentPath));
		} catch (Exception ignoreException) {
			LOGGER.error("Exception ocurred while querying user's current directory.");
		}

		return currentPath;
	}

	public static String GetSystemCurrentDirectory() {
		String currentDir = "";
		try {
			currentDir = System.getProperty("user.dir");
			LOGGER.info(String.format("Current dir using System: '%s'", currentDir));
		} catch (Exception ignoreException) {
			LOGGER.error("Exception ocurred while querying current directory using System.");
		}

		return currentDir;
	}
}
