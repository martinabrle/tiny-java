package app.demo.todo.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Random;

import app.demo.todo.service.TodoService;

@RestController
public class TodoListHealthApiController {

	private TodoService todoService;
	
	@Autowired 
	public TodoListHealthApiController(TodoService service) {
		try {
			this.todoService = service;
		}
		catch (Exception ignException) {
			this.todoService = null;
		}
	}

	public static final Logger LOGGER = LoggerFactory.getLogger(TodoListHealthApiController.class);

	@GetMapping( value = {"/health"}, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<String> getHealth() {

		LOGGER.debug("Healthiness probe called");

		var random = new Random().nextDouble();
		if (random > 0.96) {
			if (random > 0.98) {
				return new ResponseEntity<String>("RANDOM_ERROR_INTERNAL", HttpStatus.INTERNAL_SERVER_ERROR);
			}
			return new ResponseEntity<String>("RANDOM_ERROR_BAD_REQUEST", HttpStatus.BAD_REQUEST);
	    }
		return new ResponseEntity<String>("OK", HttpStatus.OK);
	}

	@GetMapping( value = {"/health/live"}, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<String> getLive() {
		LOGGER.debug("Liveness probe called");

		try {
			todoService.getTodos();
		}
		catch (Exception ignoreException) {
			return new ResponseEntity<String>("BACKEND_ERROR", HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<String>("OK", HttpStatus.OK);
	}

	@GetMapping( value = {"/health/warmup"}, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<String> warm() {
		LOGGER.debug("Warm-Up called");

		try {
			todoService.getTodos();
		}
		catch (Exception ignoreException) {
			return new ResponseEntity<String>("BACKEND_ERROR", HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<String>("OK", HttpStatus.OK);
	}
}