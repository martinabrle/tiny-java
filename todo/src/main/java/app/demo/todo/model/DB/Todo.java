package app.demo.todo.model.DB;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.persistence.Entity;
import javax.persistence.Id;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import app.demo.todo.utils.Utils;

import java.util.Date;
import java.util.Objects;
import java.util.UUID;

@Entity
public class Todo {
    public static final Logger LOGGER = LoggerFactory.getLogger(Todo.class);

    private @Id UUID id;

    private String todoText;

    private Date createdDateTime;
    
    private Date completedDateTime;

    public Todo() {
    }

    public Todo(UUID id, String todoText, Date createdDateTime, Date completedDateTime) {
        this.id = id;
        this.completedDateTime = completedDateTime;
        this.createdDateTime = createdDateTime;
        this.todoText = todoText;
    }

    public Todo(app.demo.todo.model.UI.Todo todo) {
        this.id = todo.getId();
        this.createdDateTime = todo.getCreatedDateTime();
        this.completedDateTime = todo.getCompletedDateTime();
        this.todoText = todo.getTodoText();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;
        Todo todo = (Todo) o;
        return Objects.equals(id, todo.id) &&
                ((createdDateTime == null && todo.createdDateTime == null)
                        || (createdDateTime != null && createdDateTime.compareTo(todo.createdDateTime) == 0))
                &&
                Objects.equals(todoText, todo.todoText) &&
                ((completedDateTime == null && todo.completedDateTime == null)
                        || (completedDateTime != null && completedDateTime.compareTo(todo.completedDateTime) == 0));
    }

    @Override
    public int hashCode() {

        return Objects.hash(id, createdDateTime, todoText, completedDateTime);
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getTodoText() {
        return todoText;
    }

    public void setTodoText(String todoText) {
        this.todoText = todoText;
    }

    public Date getCreatedDateTime() {
        return createdDateTime;
    }

    public void setCreatedDateTime(Date createdDateTime) {
        this.createdDateTime = createdDateTime;
    }

    public Date getCompletedDateTime() {
        return completedDateTime;
    }

    public void setCompletedDateTime(Date completedDateTime) {
        this.completedDateTime = completedDateTime;
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException ex) {
            LOGGER.error("Failed to convert Todo into a string: {}\n{}", ex.getMessage(), ex);
        }
        // This is just for the impossible case where the ObjectMapper throws an
        // exception
        return "{" +
                "id=" + id +
                ", todoText='" + Utils.toJsonValueContent(todoText) + '\'' +
                ", createdDateTime='" + Utils.toJsonValueContent(createdDateTime) + '\'' +
                ", completedDateTime='" + Utils.toJsonValueContent(completedDateTime) + '\'' +
                '}';
    }
}