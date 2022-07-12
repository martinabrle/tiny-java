package app.demo.todo.controller;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

import app.demo.todo.TodoRepository;
import app.demo.todo.TodoService;
import app.demo.todo.exception.NewTodoIsEmptyException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.model.UI.NewTodo;
import app.demo.todo.model.UI.Todo;
import app.demo.todo.model.UI.TodoList;

@Controller
@RequestMapping(value = {"/api"})
public class TodoListApiController {

	@Autowired
	private TodoRepository repository;

	public static final Logger LOGGER = LoggerFactory.getLogger(TodoListApiController.class);

	@RequestMapping( value = {"todos/"}, method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<TodoList> fetchTodos() {

		LOGGER.debug("All TODOs retrieval API called");

		TodoList retVal = null;
		try {
			retVal = TodoService.GetTodosUI(repository);
		} catch (TodosRetrievalFailedException ex) {
			return new ResponseEntity<TodoList>(HttpStatus.BAD_REQUEST);
		} catch (Exception ex) {
			return new ResponseEntity<TodoList>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<TodoList>(retVal, HttpStatus.OK);
	}

	@RequestMapping(value = "todos/{id}", method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> fetchTodo(@PathVariable(name = "id", required = true) String id) {

		LOGGER.debug("Single TODO retrieval called");

		Todo retVal = null;
		try {
			retVal = TodoService.GetTodoUI(repository, UUID.fromString(id));
		} catch (TodoNotFoundException ex) {
			return new ResponseEntity<Todo>(HttpStatus.NOT_FOUND);
		} catch (TodosRetrievalFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	}

	@RequestMapping(value = "todos/", method = RequestMethod.POST, consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	@ResponseBody
	public ResponseEntity<Todo> createTodo(@RequestBody NewTodo newTodo) {

		LOGGER.debug("TODO creation called");

		Todo retVal = null;
		try {
			if (newTodo == null) {
				throw new NewTodoIsEmptyException();
			}
			retVal = TodoService.CreateTodoUI(repository, newTodo.getTodoText());
		} catch (NewTodoIsEmptyException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
		} catch (TodoCreationFailedException ex) {
			return new ResponseEntity<Todo>(HttpStatus.BAD_GATEWAY);
		} catch (Exception ex) {
			return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
		}
		return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	}
}