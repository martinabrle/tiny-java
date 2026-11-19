package app.demo.todo.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;

import app.demo.todo.dto.Todo;
import app.demo.todo.dto.TodoPatch;
import app.demo.todo.exception.InvalidTodoException;
import app.demo.todo.exception.TodoCreationFailedException;
import app.demo.todo.exception.TodoDeleteFailedException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.exception.TodoUpdateFailedException;
import app.demo.todo.exception.TodosRetrievalFailedException;

@Service
public interface TodoService {

    public List<Todo> getTodos() throws TodosRetrievalFailedException;
    public Todo getTodo(UUID id) throws TodoNotFoundException, TodosRetrievalFailedException;
    public Todo createTodo(String todoText) throws TodoCreationFailedException, InvalidTodoException;
    public Todo updateTodo(TodoPatch patch) throws InvalidTodoException, TodoUpdateFailedException, TodoNotFoundException;
    public List<Todo> updateTodos(List<TodoPatch> patches) throws InvalidTodoException, TodoUpdateFailedException, TodoNotFoundException;
    public void deleteTodo(UUID id) throws TodoNotFoundException, TodoDeleteFailedException;
}
