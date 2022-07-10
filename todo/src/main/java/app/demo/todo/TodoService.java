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
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.model.NewTodo;
import app.demo.todo.model.Todo;
import app.demo.todo.model.TodoList;

public class TodoService {

    public static final Logger LOGGER = LoggerFactory.getLogger(TodoService.class);

    public static TodoList GetTodos(TodoRepository repository) throws TodosRetrievalFailedException {

        List<Todo> todos = null;
        TodoList retVal = null;

        LOGGER.debug("Retrieving all TODOs synchronously using GetTodos()");

        try {
            todos = repository.findAll(Sort.by(Sort.Direction.DESC, "createdDateTime"));
            retVal = TodoList.fromTodoList(todos);
            LOGGER.debug("Received back a list of TODOs as a response: {}", retVal);
        } catch (Exception ex) {
            LOGGER.error("Retrieving all TODOs failed: {}\n{}", ex.getMessage(), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }

        return retVal;
    }

    public static Todo GetTodo(TodoRepository repository, UUID id)
            throws TodoNotFoundException, TodosRetrievalFailedException {

        Todo retVal = null;

        LOGGER.debug("Retrieving a TODO synchronously using GetTodo({})", id);

        try {
            Optional<Todo> retrievedTodo = repository.findById(id);

            if (retrievedTodo.isEmpty())
                throw new TodoNotFoundException("Unable to retrieve the Todo or Todo does not exist.");

            retVal = retrievedTodo.get();

            if (retVal == null)
                throw new TodoNotFoundException("Unable to retrieve the Todo or Todo does not exist.");

            LOGGER.debug("Received back this TODO structure as a response: {}", retVal);
        } catch (TodoNotFoundException ex) {
            throw ex;
        } catch (Exception ex) {
            LOGGER.error("Retrieving the TODO {} failed: {}\n{}", id, ex.getMessage(), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }

        return retVal;
    }

    public static Todo CreateTodo(TodoRepository repository, NewTodo newTodo)
            throws TodoCreationFailedException, NewTodoIsEmptyException {
        Todo todo = null;

        if (newTodo == null)
            throw new NewTodoIsEmptyException();

        try {
            LOGGER.debug("Create a new Todo synchronously using CreateTodo({})", newTodo);
            String todoText = newTodo.getTodoText();
            if (todoText == null || todoText.trim() == "")
                throw new NewTodoIsEmptyException();

            var tmpTodo = new Todo(UUID.randomUUID(), newTodo.getTodoText());
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

}
