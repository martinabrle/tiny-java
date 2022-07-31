package app.demo.todo.controller;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import app.demo.todo.dto.NewTodo;
import app.demo.todo.dto.Todo;
import app.demo.todo.exception.NewTodoIsEmptyException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoDeleteFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.service.TodoService;

@RestController
@RequestMapping(value = {"/api"})
public class TodoListApiController {

	private TodoService todoService;
	
	@Autowired 
	public TodoListApiController(TodoService service) {
			this.todoService = service;
	}

	public static final Logger LOGGER = LoggerFactory.getLogger(TodoListApiController.class);

	@GetMapping( value = {"todos/"}, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<List<Todo>> getTodos() {

		LOGGER.debug("All TODOs retrieval API called");

		List<Todo> retVal = null;
		try {
			retVal = todoService.getTodos();
		} catch (TodosRetrievalFailedException ex) {
			return new ResponseEntity<List<Todo>>(HttpStatus.BAD_REQUEST);
		} catch (Exception ex) {
			return new ResponseEntity<List<Todo>>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<List<Todo>>(retVal, HttpStatus.OK);
	}

	@GetMapping(value = "todos/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> getTodo(@PathVariable(name = "id", required = true) String id) {

		LOGGER.debug("Single TODO retrieval called");

		Todo retVal = null;
		try {
			retVal = todoService.getTodo(UUID.fromString(id));
		} catch (TodoNotFoundException ex) {
			return new ResponseEntity<Todo>(HttpStatus.NOT_FOUND);
		} catch (TodosRetrievalFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	}

	@PostMapping(value = "todos/", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> createTodo(@RequestBody NewTodo newTodo) {

		LOGGER.debug("TODO creation called");

		Todo retVal = null;
		try {
			if (newTodo == null) {
				throw new NewTodoIsEmptyException();
			}
			retVal = todoService.createTodo(newTodo.getTodoText());
		} catch (NewTodoIsEmptyException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (TodoCreationFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_GATEWAY);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	}

	@PatchMapping(value = "todos/", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> updateTodo(@RequestBody Todo todo) {

		LOGGER.debug("TODO update called");

		Todo retVal = null;
		try {
			if (todo == null || todo.getTodoText() == null || todo.getTodoText().trim().isEmpty()) {
				throw new NewTodoIsEmptyException();
			}
			retVal = todoService.updateTodo(todo);
		} catch (NewTodoIsEmptyException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (TodoCreationFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_GATEWAY);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	}

	@DeleteMapping(value = "todos/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> deleteTodo(@PathVariable(name = "id", required = true) String id) {

		LOGGER.debug("TODO delete called");

		try {
			todoService.deleteTodo(UUID.fromString(id));
		} catch (TodoNotFoundException ex) {
			return new ResponseEntity<Todo>(HttpStatus.NOT_FOUND);
		} catch (TodoDeleteFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(HttpStatus.OK);
	}
}