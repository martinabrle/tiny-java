package app.demo.todo.repository;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.jdbc.EmbeddedDatabaseConnection;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;

import app.demo.todo.DatabaseLoader;
import app.demo.todo.entity.Todo;

@SpringBootTest
@AutoConfigureTestDatabase(connection = EmbeddedDatabaseConnection.H2)
public class TodoRepositoryTest {

    public static final Logger LOGGER = LoggerFactory.getLogger(TodoRepositoryTest.class);

	@Autowired 
    private TodoRepository todoRepository;
    
    private UUID existingTodoId = null;
    
    @BeforeEach
    void setUp() {
        if (existingTodoId == null ) {
            DatabaseLoader.initRepoWithDemoData(todoRepository);
            existingTodoId = UUID.fromString("00000000-0000-0000-0000-000000000004");
        }
    }

    @Test
    void whenValidTodoText_thenTodoShouldBeFound() {

        List<Todo> retrievedTodos = null;
        try{
            retrievedTodos = todoRepository.findByTodoText("Help build S.H.I.E.L.D.");
        }
        catch (Exception ex) {
            assertDoesNotThrow(() -> {
                throw ex;
            });
        }

        assertEquals(retrievedTodos.size(), 1);
        assertTrue(retrievedTodos.get(0) != null);
        assertTrue(retrievedTodos.get(0).getId().equals(existingTodoId));
    }

}
