package app.demo.todo;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.data.domain.Sort;

import app.demo.todo.exception.NewTodoIsEmptyException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodoUpdateFailedException;
import app.demo.todo.exception.TodosRetrievalFailedException;

public class TodoService {

    public static final Logger LOGGER = LoggerFactory.getLogger(TodoService.class);

    public static app.demo.todo.model.UI.TodoList GetTodosUI(TodoRepository repository) throws TodosRetrievalFailedException {

        List<app.demo.todo.model.DB.Todo> todos = null;
        app.demo.todo.model.UI.TodoList retVal = null;

        LOGGER.debug("Retrieving all TODOs synchronously using GetTodos()");

        try {
            todos = repository.findAll(Sort.by(Sort.Direction.DESC, "createdDateTime"));
            retVal = app.demo.todo.model.UI.TodoList.fromTodoListDB(todos);
            LOGGER.debug("Received back a list of TODOs as a response: {}", retVal);
        } catch (Exception ex) {
            LOGGER.error("Retrieving all TODOs failed: {}\n{}", ex.getMessage(), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }

        return retVal;
    }

    public static app.demo.todo.model.UI.Todo GetTodoUI(TodoRepository repository, UUID id)
      throws TodoNotFoundException, TodosRetrievalFailedException {
          return new app.demo.todo.model.UI.Todo(GetTodoDB(repository, id));
    }

    public static app.demo.todo.model.DB.Todo GetTodoDB(TodoRepository repository, UUID id)
            throws TodoNotFoundException, TodosRetrievalFailedException {

        app.demo.todo.model.DB.Todo retVal = null;

        LOGGER.debug("Retrieving a TODO synchronously using GetTodo({})", id);

        try {
            Optional<app.demo.todo.model.DB.Todo> retrievedTodo = repository.findById(id);

            if (retrievedTodo.isEmpty()) {
                throw new TodoNotFoundException("Unable to retrieve the Todo or Todo does not exist.");
            }

            retVal = retrievedTodo.get();

            if (retVal == null) {
                throw new TodoNotFoundException("Unable to retrieve the Todo or Todo does not exist.");
            }

            LOGGER.debug("Received back this TODO structure as a response: {}", retVal);
        } catch (TodoNotFoundException ex) {
            throw ex;
        } catch (Exception ex) {
            LOGGER.error("Retrieving the TODO {} failed: {}\n{}", id, ex.getMessage(), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }

        return retVal;
    }

    public static app.demo.todo.model.UI.Todo CreateTodoUI(TodoRepository repository, String todoText)
            throws TodoCreationFailedException, NewTodoIsEmptyException {
        
        return new app.demo.todo.model.UI.Todo(CreateTodoDB(repository, todoText));
    }

    public static app.demo.todo.model.DB.Todo CreateTodoDB(TodoRepository repository, String todoText)
            throws TodoCreationFailedException, NewTodoIsEmptyException {
        
        app.demo.todo.model.DB.Todo todo = null;

        if (todoText == null || todoText.trim() == "") {
            throw new NewTodoIsEmptyException();
        }

        try {
            LOGGER.debug("Create a new Todo synchronously using CreateTodo({})", todoText);

            var tmpTodo = new app.demo.todo.model.DB.Todo(UUID.randomUUID(), todoText, null, null);
            if (tmpTodo.getCreatedDateTime() == null) {
                tmpTodo.setCreatedDateTime(new Date());
            }

            todo = repository.save(tmpTodo);

            LOGGER.debug("Saved a new TODO: {}", todo);
        } catch (NewTodoIsEmptyException ex) {
            throw ex;
        } catch (Exception ex) {
            LOGGER.error("Todo creation failed: {}\n{}", ex.getMessage(), ex);
            throw new TodoCreationFailedException(ex.getMessage());
        }
        return todo;
    }

    public static app.demo.todo.model.DB.Todo UpdateTodoDB(TodoRepository repository, app.demo.todo.model.DB.Todo todo)
            throws NewTodoIsEmptyException, TodoUpdateFailedException, TodoNotFoundException {
        
        if (todo == null)
            throw new NewTodoIsEmptyException();

        try {
            LOGGER.debug("Updating an existing Todo synchronously using UpdateTodoDB({})", todo);

            Optional<app.demo.todo.model.DB.Todo> existingTodoLookup = repository.findById(todo.getId());

            if (existingTodoLookup.isEmpty())
              throw new TodoNotFoundException(String.format("Todo %o does not exist.", todo.getId()));

            var existingTodo = existingTodoLookup.get();
            existingTodo.setTodoText(todo.getTodoText());
            existingTodo.setCompletedDateTime(todo.getCompletedDateTime());

            todo = repository.save(existingTodo);

            LOGGER.debug("Updated an existing TODO: {}", todo);
        } catch (NewTodoIsEmptyException ex) {
            throw ex;
        } catch (TodoNotFoundException ex) {
            throw ex;
        } catch (Exception ex) {
            LOGGER.error("Todo creation failed: {}\n{}", ex.getMessage(), ex);
            throw new TodoUpdateFailedException(ex.getMessage());
        }
        return todo;
    }

}
