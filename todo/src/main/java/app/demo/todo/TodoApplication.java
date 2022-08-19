package app.demo.todo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import app.demo.todo.utils.AppEnvironment;

@SpringBootApplication
public class TodoApplication {
	public static final Logger LOGGER = LoggerFactory.getLogger(TodoApplication.class);

	public static final String CURRENT_DIR = AppEnvironment.GetCurrentDirectory();
	public static final String CURRENT_SYSTEM_DIR = AppEnvironment.GetSystemCurrentDirectory();

	public static void main(String[] args) {
		LOGGER.debug(String.format("Starting '%s'", TodoApplication.class.getName()));

		SpringApplication.run(TodoApplication.class, args);

		LOGGER.debug(String.format("Finishing '%s'", TodoApplication.class.getName()));
	}
}
