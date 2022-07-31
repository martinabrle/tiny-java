package app.demo.todo.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

import app.demo.todo.entity.Todo;

public interface TodoRepository extends JpaRepository<Todo, UUID> {
    List<Todo> findByTodoText(String infix);
}