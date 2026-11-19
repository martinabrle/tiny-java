package app.demo.todo.controller;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import app.demo.todo.dto.Todo;
import app.demo.todo.dto.TodoPage;
import app.demo.todo.dto.TodoPatch;
import app.demo.todo.exception.InvalidTodoException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodoUpdateFailedException;
import app.demo.todo.service.TodoService;
import app.demo.todo.utils.AppLogger;
import app.demo.todo.utils.Utils;

@Controller
public class TodoListWebController {

	public static final AppLogger LOGGER = new AppLogger(TodoListWebController.class);

	private TodoService todoService;

	@Autowired
	public TodoListWebController(TodoService service) {
		this.todoService = service;
	}

	@GetMapping("/")
	public String getTodos(Model model) {
		LOGGER.debug("TODO GET called with action '/'");

		initPageHeader(model, false);
		initPageTodoList(model);

		return "todo";
	}

	@GetMapping("/add-new")
	public String addNewGet(Model model) {
		LOGGER.debug("TODO GET called with action '/add-new'");

		initPageHeader(model, true);
		initPageTodoList(model);

		return "todo";
	}

	@PostMapping(value = "/add-new")
	public String addNew(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/add-new'");

		initPageHeader(model, true);
		processTodoList(model, page);

		return "todo";
	}

	@RequestMapping(value = "/close-msg-box", method = RequestMethod.POST)
	public String closeMsgBox(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/close-msg-box'");

		initPageHeader(model, page.getTodoText() != null);
		setFormTodoText(model, page.getTodoText());
		processTodoList(model, page);

		return "todo";
	}

	@RequestMapping(value = "/cancel", method = RequestMethod.POST)
	public String cancel(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/cancel'");

		initPageHeader(model, false);
		processTodoList(model, page);

		return "todo";
	}

	@RequestMapping(value = "/update-refresh", method = RequestMethod.POST)
	public String updateRefresh(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/update-refresh'");

		initPageHeader(model, page != null && page.getTodoText() != null);
		if (page != null && page.getTodoText() != null) {
			setFormTodoText(model, page.getTodoText());
		}
		processTodoList(model, page);

		return "todo";
	}

	@RequestMapping(value = "/submit", method = RequestMethod.POST)
	public String submit(@ModelAttribute TodoPage page, Model model) {

		LOGGER.debug("TODO POST called with action '/submit'");

		initPageHeader(model, true);

		try {
			var todo = todoService.createTodo(page.getTodoText());
			setFormMessage(model, "saved",
					String.format("Task '%s' has been saved.", Utils.shortenString(todo.getTodoText())));
			setCreateTodoMode(model, false);
		} catch (InvalidTodoException ex) {
			setFormTodoText(model, page.getTodoText());
			setFormMessage(model, "error", ex.getMessage());
		} catch (TodoCreationFailedException ex) {
			setFormTodoText(model, page.getTodoText());
			setFormMessage(model, "error", "Error while saving the new task. Please try again later.");
		}

		processTodoList(model, page);

		return "todo";
	}

	private void initPageHeader(Model model, boolean createMode) {

		model.addAttribute("createMode", createMode);
		model.addAttribute("formStatus", "");
		model.addAttribute("formMessage", "");
		model.addAttribute("todoListStatus", "");
		model.addAttribute("todoListMessage", "");
		model.addAttribute("page", new TodoPage());
	}

	private void setFormMessage(Model model, String formStatus, String formMessage) {
		model.addAttribute("formStatus", formStatus);
		model.addAttribute("formMessage", formMessage);
	}

	private void setTodoListMessage(Model model, String todoListStatus, String todoListMessage) {
		model.addAttribute("todoListStatus", todoListStatus);
		model.addAttribute("todoListMessage", todoListMessage);
	}

	private void setCreateTodoMode(Model model, boolean createMode) {
		model.addAttribute("createMode", createMode);
	}

	private void setFormTodoText(Model model, String todoText) {
		TodoPage page = null;

		if (model.containsAttribute("page")) {
			page = (TodoPage) model.getAttribute("page");
		}
		
		if (page == null) {
			page = new TodoPage();
			model.addAttribute("page", page);
		}

		page.setTodoText(todoText);
	}

	private boolean hasTodoListError(Model model) {
		return "error".equals(model.getAttribute("todoListStatus"));
	}

	private void initPageTodoList(Model model) {
		TodoPage page = null;

		if (model.containsAttribute("page")) {
			page = (TodoPage) model.getAttribute("page");
		}
		
		if (page == null) {
			page = new TodoPage();
			model.addAttribute("page", page);
		}

		try {
			var todos = todoService.getTodos();
			if (todos == null)
				todos = new ArrayList<Todo>();
			page.setTodoList(todos);
			model.addAttribute("page", page);
		} catch (Exception ex) {
			LOGGER.error(String.format("Failed to retrieve the list of TODOs (%s)", ex.getMessage()), ex);
			model.addAttribute("page", page);
			if (!this.hasTodoListError(model)) {
				// Do not overwrite a possibly moder important error
				model.addAttribute("todoListStatus", "error");
				model.addAttribute("todoListMessage", "Failed to fetch Todos. Please try again later.");
			}
		}
	}

	private void processTodoList(Model model, TodoPage page) {
		var changes = new ArrayList<TodoPatch>();
		if (page.getTodoList() != null) {
			for (Todo todo : page.getTodoList()) {
				if (todo != null && todo.getCompleted() != todo.getCompletedOrig()) {
					var patch = new TodoPatch();
					patch.setId(todo.getId());
					patch.setCompleted(todo.getCompleted());
					changes.add(patch);
				}
			}
		}

		try {
			if (!changes.isEmpty()) {
				todoService.updateTodos(changes);
			}
		} catch (InvalidTodoException | TodoNotFoundException ex) {
			setTodoListMessage(model, "error", ex.getMessage());
		} catch (TodoUpdateFailedException ex) {
			setTodoListMessage(model, "error", "Failed to update Todos. Please try again later.");
		}
		initPageTodoList(model);
	}
}