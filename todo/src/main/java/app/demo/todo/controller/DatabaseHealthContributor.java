//currently investigating if actuator needs to be extended
package app.demo.todo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.web.bind.annotation.RestController;

import app.demo.todo.service.TodoService;
import app.demo.todo.utils.AppLogger;

@RestController
public class DatabaseHealthContributor implements HealthIndicator {

	@Autowired
	private TodoService todoService;

	public static final AppLogger LOGGER = new AppLogger(DatabaseHealthContributor.class);

	@Override
	public Health health() {

		LOGGER.debug("Database health probe called");

		try {
			todoService.getTodos();
		} catch (Exception ex) {
			LOGGER.error("Database health probe failed: ", ex);
			return Health.outOfService().withException(ex).build();
		}
		LOGGER.debug("Database health probe returned OK");
		return Health.up().build();
	}
}