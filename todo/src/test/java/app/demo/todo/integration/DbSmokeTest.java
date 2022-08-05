package app.demo.todo.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;


import app.demo.todo.repository.TodoRepository;

@SpringBootTest
@ActiveProfiles("local-mi")
public class DbSmokeTest {

	@Autowired 
    private TodoRepository todoRepository;
    
    @Test
    void connectionToDbShouldWork() {
        todoRepository.count();
    }

}
