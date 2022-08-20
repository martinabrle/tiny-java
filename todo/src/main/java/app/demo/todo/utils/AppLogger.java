package app.demo.todo.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import app.demo.todo.TodoApplication;

//Using a SLf4J Logger only after the app has been inited as there were some weird issues,
//while logging in the property transformation part (AppEnvironmentListener)
public class AppLogger {
    private final Class<?> clazz;
    private Logger logger = null;

    public AppLogger(Class<?> clazz) {
        this.clazz = clazz;
    }

    public void debug(String message) {
        if (!TodoApplication.isInitialized()) {
            System.out.println(message);
        }
        if (logger == null) {
            logger = LoggerFactory.getLogger(clazz);
        }
        logger.debug(message);
    }

    public void error(String message) {
        if (!TodoApplication.isInitialized()) {
            System.err.println(message);
        }
        if (logger == null) {
            logger = LoggerFactory.getLogger(clazz);
        }
        logger.error(message);
    }

    public void info(String message) {
        if (!TodoApplication.isInitialized()) {
            System.out.println(message);
        }
        if (logger == null) {
            logger = LoggerFactory.getLogger(clazz);
        }
        logger.info(message);
    }
}
