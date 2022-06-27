package app.demo.todo.exception;

public class TodoNotFoundException extends RuntimeException {

    public TodoNotFoundException(String message) {
        super(String.format(message));
    }
}