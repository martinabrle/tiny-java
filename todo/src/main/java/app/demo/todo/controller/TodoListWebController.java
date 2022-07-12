package app.demo.todo.controller;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import app.demo.todo.TodoRepository;
import app.demo.todo.TodoService;
import app.demo.todo.model.UI.Todo;
import app.demo.todo.model.UI.TodoList;
import app.demo.todo.model.UI.TodoPage;
import app.demo.todo.utils.Utils;

@Controller
public class TodoListWebController {

	@Autowired
	private TodoRepository repository;

	public static final Logger LOGGER = LoggerFactory.getLogger(TodoListWebController.class);


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

	@RequestMapping(value="/add-new", method=RequestMethod.POST)
	public String addNew(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/add-new'");

		initPageHeader(model, true);
		processTodoList(model, page);
		
		return "todo";
	}

	@RequestMapping(value="/cancel", method=RequestMethod.POST)
	public String cancel(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/cancel'");
		
		initPageHeader(model, false);
		processTodoList(model, page);
  
		return "todo";
	}

	@RequestMapping(value="/update-refresh", method=RequestMethod.POST)
	public String updateRefresh(@ModelAttribute TodoPage page, Model model) {
		LOGGER.debug("TODO POST called with action '/update-refresh'");
		
		initPageHeader(model, page != null && page.getTodoText() != null);
		if (page.getTodoText() != null) {
			setFormTodoText(model, page.getTodoText());
		}
		processTodoList(model, page);
  
		return "todo";
	}

	@RequestMapping(value="/submit", method=RequestMethod.POST)
	public String submit(@ModelAttribute TodoPage page, Model model) {

		LOGGER.debug("TODO POST called with action '/submit' ", page);

		initPageHeader(model, true);

		try {
			if (page.getTodoText() == null || page.getTodoText().trim() == "") {
				LOGGER.error("Unable to save a new TODO; TODO is empty.");
				setCreateTodoMode(model, true);
				setFormMessage(model, "error", "New Todo cannot be empty. Please fill in the text.");
				processTodoList(model, page);
			} else {
				var todo = TodoService.CreateTodoDB(repository, page.getTodoText());
				
				setFormMessage(model, "saved", String.format("Task '%s' has been saved.", Utils.shortenString(page.getTodoText())));

				processTodoList(model, page);
				if (!hasTodoListError(model)) {
					initPageTodoList(model);
				} else {
					addToTodoList(model, todo);
				}
				setCreateTodoMode(model, false);
			}
		} catch (Exception ex) {
			LOGGER.error("Failed to save a new TODO: {}\n{}", ex.getMessage(), ex);
			setCreateTodoMode(model, true);
			setTodoListMessage(model, "error", "Error while saving the new task. Please try again later.");
		}
	
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
		TodoPage page;
		
		if (model.containsAttribute("page")) {
			page = (TodoPage)model.getAttribute("page");
		} else {
			page = new TodoPage();
			model.addAttribute("page", page);
		}
		page.setTodoText(todoText);
	}

	private boolean hasTodoListError(Model model) {
		return model != null && model.getAttribute("todoListStatus") == "error";
	}

	private void initPageTodoList(Model model) {
		TodoPage page;
		
		if (model.containsAttribute("page")) {
			page = (TodoPage)model.getAttribute("page");
		} else {
			page = new TodoPage();
			model.addAttribute("page", page);
		}
  
		try {
			var todos = TodoService.GetTodosUI(repository);
			if (todos == null)
			  todos = new TodoList();
			page.setTodoList(todos);
			model.addAttribute("page", page);
		} catch (Exception ex) {
			LOGGER.error("Failed to retrieve the list of TODOs: {}\n{}", ex.getMessage(), ex);
			model.addAttribute("page", page);
			model.addAttribute("todoListStatus", "error");
			model.addAttribute("todoListMessage", "Failed to fetch Todos. Please try again later.");
		}
	}

	private void addToTodoList(Model model, app.demo.todo.model.DB.Todo todoDB) {
		TodoPage page;
		if (model.containsAttribute("page")) {
		  page = (TodoPage)model.getAttribute("page");
		} else {
		  page = new TodoPage();
		  model.addAttribute("page", page);
		}

		if (page.getTodoList() == null) {
			page.setTodoList(new TodoList());
		}

		page.getTodoList().add(0, new Todo(todoDB));
	}

	private void setPageTodoList(Model model, TodoList todoList) {
		TodoPage page;
		
		if (model.containsAttribute("page")) {
		  page = (TodoPage)model.getAttribute("page");
		} else {
		  page = new TodoPage();
		  model.addAttribute("page", page);
		}

		page.setTodoList(todoList);
	}

	private void processTodoList(Model model, TodoPage page) {
		try {
			TodoList todoList = page.getTodoList();
			if (todoList != null) {
				//TODO: refactor to using Sets
				for (Todo todo : todoList) {
					if (todo.getCompleted() != todo.getCompletedOrig())
					{
						var todoDB = TodoService.GetTodoDB(repository, todo.getId());
		
						if (todo.getCompleted() && todoDB.getCompletedDateTime() == null) {
							todoDB.setCompletedDateTime(new Date());
							var updatedTodoDB = TodoService.UpdateTodoDB(repository, todoDB);
							todo.initFromTodo(updatedTodoDB);
						} else if (!todo.getCompleted() && todoDB.getCompletedDateTime() != null) {
							todoDB.setCompletedDateTime(null);
							var updatedTodoDB = TodoService.UpdateTodoDB(repository, todoDB);
							todo.initFromTodo(updatedTodoDB);
						} else if (todo.getCompletedDateTime() != todoDB.getCompletedDateTime()) {
							todo.initFromTodo(todoDB);
						}
					}
				}
			}
			initPageTodoList(model);
		}
		catch (Exception ex) {
			setTodoListMessage(model, "error", "An error has occured while updating Todos. Please try again later.");
			setPageTodoList(model, page.getTodoList());
		}		
	}
}