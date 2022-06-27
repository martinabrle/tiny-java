package app.demo.todo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
	public static final Logger LOGGER = LoggerFactory.getLogger(TodoApplication.class);


	public static void main(String[] args) {
		LOGGER.debug("Starting '{}'", TodoApplication.class.getName());
		SpringApplication.run(TodoApplication.class, args);
		LOGGER.debug("Finishing '{}'", TodoApplication.class.getName());
	}

}
