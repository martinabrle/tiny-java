package app.demo.todo.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import app.demo.todo.dto.NewTodo;
import app.demo.todo.dto.Todo;
import app.demo.todo.dto.TodoPatch;
import app.demo.todo.exception.InvalidTodoException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoDeleteFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodoUpdateFailedException;
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.service.TodoService;

@RestController
@RequestMapping(value = "/api", produces = MediaType.APPLICATION_JSON_VALUE)
public class TodoListApiController {

	private final TodoService todoService;

	public TodoListApiController(TodoService service) {
		this.todoService = service;
	}

	@GetMapping({"/todos", "/todos/"})
	public List<Todo> getTodos() {
		return todoService.getTodos();
	}

	@GetMapping("/todos/{id}")
	public Todo getTodo(@PathVariable("id") UUID id) {
		return todoService.getTodo(id);
	}

	@PostMapping(value = {"/todos", "/todos/"}, consumes = MediaType.APPLICATION_JSON_VALUE)
	public Todo createTodo(@RequestBody NewTodo newTodo) {
		return todoService.createTodo(newTodo.getTodoText());
	}

	@PatchMapping(value = "/todos/{id}", consumes = MediaType.APPLICATION_JSON_VALUE)
	public Todo updateTodo(@PathVariable("id") UUID id, @RequestBody TodoPatch patch) {
		if (patch.getId() != null && !id.equals(patch.getId())) {
			throw new InvalidTodoException("Todo ID does not match the request URL.");
		}
		patch.setId(id);
		return todoService.updateTodo(patch);
	}

	@PatchMapping(value = {"/todos", "/todos/"}, consumes = MediaType.APPLICATION_JSON_VALUE)
	public List<Todo> updateTodos(@RequestBody List<TodoPatch> patches) {
		return todoService.updateTodos(patches);
	}

	@DeleteMapping("/todos/{id}")
	public void deleteTodo(@PathVariable("id") UUID id) {
		todoService.deleteTodo(id);
	}

	@ExceptionHandler(InvalidTodoException.class)
	public ResponseEntity<Void> invalidTodo() {
		return ResponseEntity.badRequest().build();
	}

	@ExceptionHandler(TodoNotFoundException.class)
	public ResponseEntity<Void> todoNotFound() {
		return ResponseEntity.notFound().build();
	}

	@ExceptionHandler({TodosRetrievalFailedException.class, TodoCreationFailedException.class,
			TodoUpdateFailedException.class, TodoDeleteFailedException.class})
	public ResponseEntity<Void> storageFailure() {
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	}
}