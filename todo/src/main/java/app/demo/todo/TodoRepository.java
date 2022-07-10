package app.demo.todo;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import app.demo.todo.model.Todo;

public interface TodoRepository extends JpaRepository<Todo, UUID> {

}