package app.demo.todo.dto;

import java.util.Date;
import java.util.UUID;

public class TodoPatch {
    private UUID id;
    private String todoText;
    private Boolean completed;
    private Date completedDateTime;
    private boolean completedDateTimeProvided;

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

    public Boolean getCompleted() {
        return completed;
    }

    public void setCompleted(Boolean completed) {
        this.completed = completed;
    }

    public Date getCompletedDateTime() {
        return completedDateTime;
    }

    public void setCompletedDateTime(Date completedDateTime) {
        this.completedDateTime = completedDateTime;
        this.completedDateTimeProvided = true;
    }

    public boolean hasCompletedDateTime() {
        return completedDateTimeProvided;
    }
}
