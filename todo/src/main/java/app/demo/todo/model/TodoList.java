package app.demo.todo.model;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class TodoList extends ArrayList<Todo> {

    public static final Logger LOGGER = LoggerFactory.getLogger(Todo.class);

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException ex) {
            LOGGER.error("Failed to convert TodoList into a string: {}\n{}", ex.getMessage(), ex);
        }
        // This is just for the impossible case where the ObjectMapper throws an
        // exception
        String retVal = "{ ";
        for (int i = 0; i < this.size(); i++) {
            if (i > 0)
                retVal += ",";
            retVal += this.get(i).toString();
        }
        retVal += " }";
        return retVal;
    }

    public static final TodoList fromTodoList(final List<Todo> todos) {
        TodoList retVal = null;

        if (todos != null) {
            retVal = new TodoList();
            for (Todo e : todos) {
                retVal.add(e);
            }
        }
        return retVal;
    }
}
