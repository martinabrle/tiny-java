package app.demo.todo.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import app.demo.todo.dto.Todo;
import app.demo.todo.dto.TodoPatch;
import app.demo.todo.exception.InvalidTodoException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoDeleteFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodoUpdateFailedException;
import app.demo.todo.exception.TodosRetrievalFailedException;
import app.demo.todo.repository.TodoRepository;
import app.demo.todo.utils.AppLogger;

@Service
public class TodoServiceImpl implements TodoService {

    private static final int MAX_TODO_TEXT_LENGTH = 255;

    @Autowired
    private TodoRepository repository;

    public static final AppLogger LOGGER = new AppLogger(TodoServiceImpl.class);

    public List<Todo> getTodos() throws TodosRetrievalFailedException {

        List<Todo> retVal = null;

        LOGGER.debug("Retrieving all TODOs synchronously using getTodos()");

        try {
            var todoEntityList = repository.findAll(Sort.by(Sort.Direction.DESC, "createdDateTime"));

            retVal = new ArrayList<Todo>();
            for (var e : todoEntityList) {
                retVal.add(new Todo(e.getId(), e.getTodoText(), e.getCreatedDateTime(), e.getCompletedDateTime(),
                        e.getCompletedDateTime() != null));
            }
        } catch (Exception ex) {
            LOGGER.error(String.format("Retrieving all TODOs failed (%s)", ex.getMessage()), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }

        LOGGER.debug("Retrieved all TODOs synchronously using getTodos()");

        return retVal;
    }

    public Todo getTodo(UUID id)
            throws TodoNotFoundException, TodosRetrievalFailedException {

        Todo retVal = null;

        LOGGER.debug(String.format("Retrieving a TODO synchronously using getTodo('%s')", id));

        try {
            var retrievedOptionalTodoEntity = repository.findById(id);

            if (!retrievedOptionalTodoEntity.isPresent()) {
                throw new TodoNotFoundException(
                        String.format("Unable to retrieve Todo '%s'; Todo does not exist (1).", id));
            }

            var retrievedTodoEntity = retrievedOptionalTodoEntity.get();

            if (retrievedTodoEntity == null) {
                throw new TodoNotFoundException(String.format("Unable to retrieve Todo '%s' (2).", id));
            }

            retVal = new Todo(retrievedTodoEntity.getId(), retrievedTodoEntity.getTodoText(),
                    retrievedTodoEntity.getCreatedDateTime(), retrievedTodoEntity.getCompletedDateTime(),
                    retrievedTodoEntity.getCompletedDateTime() != null);
            
        } catch (TodoNotFoundException ex) {
            throw ex;
        } catch (Exception ex) {
            LOGGER.error(String.format("Retrieving the TODO '%s' failed (%s)", id, ex.getMessage()), ex);
            throw new TodosRetrievalFailedException(ex.getMessage());
        }
        
        LOGGER.debug(String.format("Retrieved a TODO synchronously using getTodo('%s')", id));

        return retVal;
    }

    public Todo createTodo(String todoText)
            throws TodoCreationFailedException, InvalidTodoException {

        validateTodoText(todoText);

        try {
            var todoEntity = new app.demo.todo.entity.Todo(UUID.randomUUID(), todoText, new Date(), null);
            Todo todo = new Todo(repository.save(todoEntity));
            LOGGER.debug(String.format("Created a new Todo with Id '%s'", todo.getId()));
            return todo;
        } catch (DataAccessException ex) {
            LOGGER.error("Todo creation failed", ex);
            throw new TodoCreationFailedException(ex.getMessage());
        }
    }

    @Override
    @Transactional
    public Todo updateTodo(TodoPatch patch) {
        return updateTodos(Collections.singletonList(patch)).get(0);
    }

    @Override
    public void deleteTodo(UUID id) {
        if (id == null) {
            throw new InvalidTodoException("Todo ID cannot be empty.");
        }

        try {
            repository.deleteById(id);
        } catch (EmptyResultDataAccessException ex) {
            throw notFound(id);
        } catch (DataAccessException ex) {
            LOGGER.error(String.format("Deleting Todo '%s' failed", id), ex);
            throw new TodoDeleteFailedException(ex.getMessage());
        }
    }

    @Override
    @Transactional
    public List<Todo> updateTodos(List<TodoPatch> patches) {
        if (patches == null) {
            throw new InvalidTodoException("Todo updates cannot be null.");
        }

        Map<UUID, TodoPatch> updates = new LinkedHashMap<>();
        for (TodoPatch patch : patches) {
            if (patch == null || patch.getId() == null) {
                throw new InvalidTodoException("Each Todo update must have an ID.");
            }
            if (patch.getTodoText() != null) {
                validateTodoText(patch.getTodoText());
            }
            if (updates.putIfAbsent(patch.getId(), patch) != null) {
                throw new InvalidTodoException("A Todo can only appear once in an update.");
            }
        }

        if (updates.isEmpty()) {
            return Collections.emptyList();
        }

        try {
            Map<UUID, app.demo.todo.entity.Todo> existing = new HashMap<>();
            for (var entity : repository.findAllById(updates.keySet())) {
                existing.put(entity.getId(), entity);
            }
            for (UUID id : updates.keySet()) {
                if (!existing.containsKey(id)) {
                    throw notFound(id);
                }
            }

            List<Todo> result = new ArrayList<>(updates.size());
            for (TodoPatch patch : updates.values()) {
                var entity = existing.get(patch.getId());
                if (patch.getTodoText() != null) {
                    entity.setTodoText(patch.getTodoText());
                }
                if (Boolean.FALSE.equals(patch.getCompleted())) {
                    entity.setCompletedDateTime(null);
                } else if (Boolean.TRUE.equals(patch.getCompleted())) {
                    if (entity.getCompletedDateTime() == null) {
                        entity.setCompletedDateTime(new Date());
                    }
                } else if (patch.hasCompletedDateTime()) {
                    entity.setCompletedDateTime(patch.getCompletedDateTime());
                }
                result.add(new Todo(entity));
            }
            repository.flush();
            return result;
        } catch (DataAccessException ex) {
            LOGGER.error("Todo update failed", ex);
            throw new TodoUpdateFailedException(ex.getMessage());
        }
    }

    private static void validateTodoText(String todoText) {
        if (todoText == null || todoText.isBlank()) {
            throw new InvalidTodoException("Todo text cannot be empty.");
        }
        if (todoText.length() > MAX_TODO_TEXT_LENGTH) {
            throw new InvalidTodoException("Todo text cannot exceed " + MAX_TODO_TEXT_LENGTH + " characters.");
        }
    }

    private static TodoNotFoundException notFound(UUID id) {
        return new TodoNotFoundException(String.format("Todo '%s' does not exist.", id));
    }
}
