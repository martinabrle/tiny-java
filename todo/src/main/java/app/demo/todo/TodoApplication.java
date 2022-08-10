package app.demo.todo;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
	public static final Logger LOGGER = LoggerFactory.getLogger(TodoApplication.class);
	public static final String CURRENT_DIR = GetCurrentDirectory();
	public static final String CURRENT_SYSTEM_DIR = GetSystemCurrentDirectory();

	public static void main(String[] args) {
		LOGGER.debug("Starting '{}'", TodoApplication.class.getName());
		SpringApplication.run(TodoApplication.class, args);
		LOGGER.debug("Finishing '{}'", TodoApplication.class.getName());
	}

	public static String GetCurrentDirectory() {
		String currentPath = "";

		try {
			currentPath = new java.io.File(".").getCanonicalPath();
		} catch (IOException ignoreException) {
			System.out.println("ERROR: IO Exception ocurred while querying user's current directory.");
		}
		System.out.println("Current dir:" + currentPath);

		return currentPath;
	}

	public static String GetSystemCurrentDirectory() {

		String currentDir = System.getProperty("user.dir");
		System.out.println("Current dir using System:" + currentDir);

		return currentDir;
	}

}
