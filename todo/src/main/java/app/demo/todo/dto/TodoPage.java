package app.demo.todo.dto;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import app.demo.todo.utils.Utils;

public class TodoPage {

    public static final Logger LOGGER = LoggerFactory.getLogger(TodoPage.class);

    private String todoText;

    private List<Todo> todoList;

    public TodoPage() {
        todoList = new ArrayList<Todo>();
    }

    public String getTodoText() {
        return todoText;
    }

    public void setTodoText(String text) {
        todoText = text;
    }

    public List<Todo> getTodoList() {
        return todoList;
    }

    public void setTodoList(List<Todo> todoList) {
        this.todoList = todoList;
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException ex) {
            LOGGER.error("Failed to convert TodoPAge into a string: {}\n{}", ex.getMessage(), ex);
        }
        // This is just for the impossible case where the ObjectMapper throws an
        // exception
        return "{" +
                " 'todoText': '" + Utils.toJsonValueContent(todoText) + "', " +
                " 'todoList': " + todoList.toString() +
                '}';
    }
}