package app.demo.todo.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.jdbc.EmbeddedDatabaseConnection;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;

import app.demo.todo.DatabaseLoader;
import app.demo.todo.dto.Todo;
import app.demo.todo.dto.TodoPatch;
import app.demo.todo.exception.InvalidTodoException;
import app.demo.todo.exception.TodoNotFoundException;
import app.demo.todo.repository.TodoRepository;
import app.demo.todo.utils.AppLogger;

@SpringBootTest(properties = {"spring.profiles.active=local", "server.port=8080"})
@AutoConfigureTestDatabase(connection = EmbeddedDatabaseConnection.H2)
public class TodoServiceTest {
    
    public static final AppLogger LOGGER = new AppLogger(TodoServiceTest.class);

	@Autowired 
    private TodoService todoService;

	@Autowired 
    private TodoRepository todoRepository;
    
    private UUID existingTodoId = null;

    @BeforeEach
    void setUp() {
        if (existingTodoId == null ) {
            DatabaseLoader.initRepoWithDemoData(todoRepository);
            existingTodoId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        }
    }

    @Test
    void always_retrieveTodos() {

        assertDoesNotThrow(() -> {
            var retrievedTodos = todoService.getTodos();

            if (retrievedTodos == null || retrievedTodos.size() == 0) {
                throw new Exception("Empty Todo List retrieved.");
            }
        });
    }

    @Test
    void whenValidTodoId_thenTodoShouldBeFound() {

        assertDoesNotThrow(() -> {
            Todo retrievedTodo = todoService.getTodo(existingTodoId);
            assertEquals(existingTodoId, retrievedTodo.getId());
        });
    }

    @Test
    void whenInvalidTodoId_thenTodoShouldNotBeFound() {

        UUID todoId = UUID.fromString("11111111-0000-0000-0000-000000000002");
        
        assertThrows(TodoNotFoundException.class, () -> todoService.getTodo(todoId));
    }

    @Test
    void whenValidTodo_thenTodoShouldBeCreated() {

        assertDoesNotThrow(() -> {
            String text = "x".repeat(255);
            Todo createdTodo = todoService.createTodo(text);
            try {
                assertEquals(text, todoService.getTodo(createdTodo.getId()).getTodoText());
            } finally {
                todoService.deleteTodo(createdTodo.getId());
            }
        });
    }

    @Test
    void whenInvalidTodo_thenTodoShouldNotBeCreated() {

        assertThrows(InvalidTodoException.class, () -> todoService.createTodo("  "));
        assertThrows(InvalidTodoException.class, () -> todoService.createTodo("x".repeat(256)));
    }

    @Test
    void whenValidTodoId_thenTodoShouldBeDeleted() {

        assertDoesNotThrow(() -> {
            Todo createdTodo = todoService.createTodo("Test deleting Todos");
            if (createdTodo.getId() == null) {
                throw new Exception("Failed creating the testing Todo.");
            }
            todoService.deleteTodo(createdTodo.getId());
        });
    }

    @Test
    void whenInvalidTodoId_thenTodoShouldNotBeDeleted() {

        assertThrows(TodoNotFoundException.class, () -> {
            UUID todoId = UUID.fromString("11111111-0000-0000-0000-000000000002");
            
            todoService.deleteTodo(todoId);
        });
    }

    @Test
    void whenValidTodo_thenTodoShouldBeUpdated() {

        assertDoesNotThrow(() -> {
            Todo createdTodo = todoService.createTodo("Test it all");
            if (createdTodo.getId() == null || createdTodo.getTodoText().compareTo("Test it all") != 0) {
                throw new Exception("Invalid Todo created.");
            }

            TodoPatch patch = new TodoPatch();
            patch.setId(createdTodo.getId());
            patch.setTodoText("Update it all");

            try {
                Todo updatedTodo = todoService.updateTodo(patch);
                assertEquals(createdTodo.getId(), updatedTodo.getId());
                assertEquals("Update it all", todoService.getTodo(updatedTodo.getId()).getTodoText());
            } finally {
                todoService.deleteTodo(createdTodo.getId());
            }

        });
    }

    
    @Test
    void whenInvalidTodo_thenTodoShouldNotBeUpdated() {

        TodoPatch patch = new TodoPatch();
        patch.setId(existingTodoId);
        patch.setTodoText("");
        assertThrows(InvalidTodoException.class, () -> todoService.updateTodo(patch));
    }
}
