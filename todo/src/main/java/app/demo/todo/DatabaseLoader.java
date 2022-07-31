package app.demo.todo;

import java.util.Date;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import app.demo.todo.repository.TodoRepository;

@Component
public class DatabaseLoader implements CommandLineRunner {

        public static final Logger LOGGER = LoggerFactory.getLogger(DatabaseLoader.class);

        private final TodoRepository todoRepository;

        @Value("${app.demo.todo.load-demo-data}")
        private String loadDemoData;

        @Autowired 
        public DatabaseLoader(TodoRepository repository) {
                todoRepository = repository;
        }

        @Override
        public void run(String... strings) throws Exception {
                if (loadDemoData()) {
                        LOGGER.debug("Loading default data");
                        DatabaseLoader.initRepoWithDemoData(todoRepository);
                } else {
                        LOGGER.debug("Skipping demo data load");
                }
        }

        public static void initRepoWithDemoData(TodoRepository todoRepository) {
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000001"), "Create Stark Enterprises", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000002"), "Invent the first Iron Man Suit", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000003"), "Become a Hero", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000004"), "Help build S.H.I.E.L.D.", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000005"), "Form the Avengers", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000006"), "Put Hawkeye on the right path", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000007"), "Make Stark Industries a massive success", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000008"), "Keep escaping death in the most Tony Stark way possible", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000009"), "Learn Spring boot", new Date(), null));
                todoRepository.save(
                        new app.demo.todo.entity.Todo(UUID.fromString("00000000-0000-0000-0000-000000000010"), "Deploy a multi tier Spring boot app into Azure", new Date(), null));
        
        }

        private boolean loadDemoData() {
                return this.loadDemoData != null && this.loadDemoData.equalsIgnoreCase("true");
        }
}