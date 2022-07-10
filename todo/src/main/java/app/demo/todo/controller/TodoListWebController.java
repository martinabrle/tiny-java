package app.demo.todo.controller;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import app.demo.todo.TodoRepository;
import app.demo.todo.TodoService;
import app.demo.todo.exception.NewTodoIsEmptyException;
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.model.NewTodo;
import app.demo.todo.model.Todo;
import app.demo.todo.model.TodoList;

@Controller
public class TodoListWebController {

	@Autowired
	private TodoRepository repository;

	public static final Logger LOGGER = LoggerFactory.getLogger(TodoListWebController.class);

	@GetMapping("/")
	public String getTodos(@RequestParam(name = "name", required = false, defaultValue = "World") String name,
			Model model) {

		LOGGER.debug("TODOs retrieval called");

		model.addAttribute("status", "");
		model.addAttribute("message", "");
		model.addAttribute("newTodo", new NewTodo());
		model.addAttribute("createdTodoId", UUID.fromString("0-0-0-0-0"));
		model.addAttribute("todos", new TodoList());
		model.addAttribute("createTodoMode", false);
		try {
			model.addAttribute("todos", TodoService.GetTodos(repository));
		} catch (Exception ex) {
			LOGGER.error("Failed to retrieve the list of TODOs: {}\n{}", ex.getMessage(), ex);
			model.addAttribute("status", "error");
			model.addAttribute("message", "Failed to fetch Todos. Please try again later.");
		}
		return "todo";
	}

	@GetMapping("/create")
	public String create(Model model) {

		LOGGER.debug("TODOs retrieval called");

		model.addAttribute("status", "");
		model.addAttribute("message", "");
		model.addAttribute("newTodo", new NewTodo());
		model.addAttribute("createdTodoId", UUID.fromString("0-0-0-0-0"));
		model.addAttribute("todos", new TodoList());
		model.addAttribute("createTodoMode", true);
		try {
			model.addAttribute("todos", TodoService.GetTodos(repository));
		} catch (Exception ex) {
			LOGGER.error("Failed to retrieve the list of TODOs: {}\n{}", ex.getMessage(), ex);
			model.addAttribute("status", "error");
			model.addAttribute("message", "Failed to fetch Todos. Please try again later.");
		}
		return "todo";
	}

	@PostMapping("/")
	public String todoSubmit(@ModelAttribute NewTodo newTodo, Model model) {

		LOGGER.debug("TODO creation called", newTodo);

		model.addAttribute("todos", new TodoList());
		model.addAttribute("status", "");
		model.addAttribute("newTodo", newTodo);
		model.addAttribute("createdTodoId", UUID.fromString("0-0-0-0-0"));
		model.addAttribute("message", "");
		model.addAttribute("createTodoMode", false);

		boolean isError = false;
		try {
			if (newTodo == null) {
				throw new NewTodoIsEmptyException();
			}

			Todo todo = TodoService.CreateTodo(repository, newTodo);
			model.addAttribute("status", "saved");
			model.addAttribute("createdTodoId", todo.getId());
			String taskStrParm = todo.getTodoText();
			if (taskStrParm != null && taskStrParm.length() > 5)
				taskStrParm = taskStrParm.substring(0, 4) + "...";
			model.addAttribute("message", String.format("Task '%s' has been saved.", taskStrParm));
			NewTodo newTodoEmpty = new NewTodo();
			model.addAttribute("newTodo", newTodoEmpty);
		} catch (NewTodoIsEmptyException ex) {
			isError = true;
			LOGGER.error("Failed to save a new TODO: {}\n{}", ex.getMessage(), ex);
			model.addAttribute("status", "error");
			model.addAttribute("message", "New Todo cannot be empty. Please fill in the text.");
		} catch (Exception ex) {
			isError = true;
			LOGGER.error("Failed to save a new TODO: {}\n{}", ex.getMessage(), ex);
			model.addAttribute("status", "error");
			model.addAttribute("message", "Error while saving the new task. Please try again later.");
		}

		try {
			model.addAttribute("todos", TodoService.GetTodos(repository));
		} catch (TodosRetrievalFailedException e) {
			if (!isError) {
				// it's more important to display that "waiting for task saved" message, than
				// "error while retrieving existing tasks" message
				model.addAttribute("status", "error");
				model.addAttribute("message",
						"New Todo has been saved, but we failed to fetch the list of all Todos. Please try again later.");
			}
			isError = true;
		}
		return "todo";
	}

	// @RequestMapping(value = "/todos/{id}", method = RequestMethod.GET, produces = "application/json")
	// @ResponseBody
	// public ResponseEntity<Todo> fetchTodo(@PathVariable(name = "id", required = true) String id) {
	// 	Todo retVal = null;
	// 	try {
	// 		retVal = TodoService.GetTodo(repository, UUID.fromString(id));
	// 	} catch (TodoNotFoundException ex) {
	// 		return new ResponseEntity<Todo>(HttpStatus.NOT_FOUND);
	// 	} catch (TodosRetrievalFailedException ex) {
	// 		return new ResponseEntity<Todo>(HttpStatus.BAD_REQUEST);
	// 	} catch (Exception ex) {
	// 		return new ResponseEntity<Todo>(HttpStatus.INTERNAL_SERVER_ERROR);
	// 	}
	// 	return new ResponseEntity<Todo>(retVal, HttpStatus.OK);
	// }
}