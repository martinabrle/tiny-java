package app.demo.todo.integration;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;


import app.demo.todo.repository.TodoRepository;

@SpringBootTest
public class DbSmokeTest {

	@Autowired 
    private TodoRepository todoRepository;
    
    @Test
    void connectionToDbShouldWork() {
        todoRepository.count();
    }

}
