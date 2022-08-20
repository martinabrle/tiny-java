package app.demo.todo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import app.demo.todo.utils.AppEnvironment;
import app.demo.todo.utils.AppLogger;

@SpringBootApplication
public class TodoApplication {
	
	public static final AppLogger LOGGER = new AppLogger(TodoApplication.class);

	public static final String CURRENT_DIR = AppEnvironment.GetCurrentDirectory();
	public static final String CURRENT_SYSTEM_DIR = AppEnvironment.GetSystemCurrentDirectory();
	private static boolean STARTUP_FINISHED = false;

	public static void main(String[] args) {
		System.out.println(String.format("Starting '%s'", TodoApplication.class.getName()));

		SpringApplication.run(TodoApplication.class, args);

		STARTUP_FINISHED = true;

		System.out.println(String.format("Finishing '%s'", TodoApplication.class.getName()));
	}

	public static boolean isInitialized() {
		return STARTUP_FINISHED;
	}
}
