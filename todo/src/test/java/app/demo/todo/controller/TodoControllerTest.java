package app.demo.todo.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import app.demo.todo.repository.TodoRepository;
import app.demo.todo.service.TodoService;

@SpringBootTest(properties = {"spring.profiles.active=local", "server.port=8080"})
@AutoConfigureMockMvc
class TodoControllerTest {
    @Autowired
    private MockMvc mvc;

    @Autowired
    private TodoService service;

    @Autowired
    private TodoRepository repository;

    private final List<UUID> createdIds = new ArrayList<>();

    @AfterEach
    void cleanUp() {
        repository.deleteAllByIdInBatch(createdIds);
    }

    @Test
    void singlePatchUsesUrlIdAndRejectsMismatchedBodyId() throws Exception {
        UUID id = createTodo("Original");
        UUID other = createTodo("Other");

        mvc.perform(patch("/api/todos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                .content("{\"id\":\"" + other + "\",\"todoText\":\"Should not be saved\"}"))
                .andExpect(status().isBadRequest());
        assertEquals("Other", service.getTodo(other).getTodoText());

        mvc.perform(patch("/api/todos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                .content("{\"completed\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.todoText").value("Original"))
                .andExpect(jsonPath("$.completed").value(true));
        assertNotNull(service.getTodo(id).getCompletedDateTime());
    }

    @Test
    void invalidIdsReturnBadRequestAndMissingIdsReturnNotFound() throws Exception {
        mvc.perform(get("/api/todos/not-a-uuid")).andExpect(status().isBadRequest());
        mvc.perform(delete("/api/todos/not-a-uuid")).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/todos/{id}", UUID.randomUUID()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"completed\":true}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteDoesNotRequireContentType() throws Exception {
        UUID id = createTodo("Delete me");
        mvc.perform(delete("/api/todos/{id}", id)).andExpect(status().isOk());
        mvc.perform(delete("/api/todos/{id}", id)).andExpect(status().isNotFound());
    }

    @Test
    void bulkPatchConfirmsUnchangedItemsAndPreservesCompletionTime() throws Exception {
        UUID id = createTodo("Original");
        mvc.perform(patch("/api/todos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                .content("{\"completed\":true}"))
                .andExpect(status().isOk());
        long completionTime = service.getTodo(id).getCompletedDateTime().getTime();

        mvc.perform(patch("/api/todos/").contentType(MediaType.APPLICATION_JSON)
                .content("[{\"id\":\"" + id + "\",\"completed\":true}]"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(id.toString()))
                .andExpect(jsonPath("$[0].completed").value(true));
        assertEquals(completionTime, service.getTodo(id).getCompletedDateTime().getTime());
        mvc.perform(patch("/api/todos").contentType(MediaType.APPLICATION_JSON)
                .content("[{\"id\":\"" + id + "\",\"todoText\":\"Renamed\"}]"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].completed").value(true));
        assertEquals(completionTime, service.getTodo(id).getCompletedDateTime().getTime());
    }

    @Test
    void bulkPatchDoesNotSaveAnyChangesWhenAnIdIsMissing() throws Exception {
        UUID id = createTodo("Original");
        mvc.perform(patch("/api/todos/").contentType(MediaType.APPLICATION_JSON)
                .content("[{\"id\":\"" + id + "\",\"todoText\":\"Renamed\"},"
                        + "{\"id\":\"" + UUID.randomUUID() + "\",\"completed\":true}]"))
                .andExpect(status().isNotFound());
        assertEquals("Original", service.getTodo(id).getTodoText());
    }

    @Test
    void timestampOnlyPatchStillSupportsCompletingAndReopening() throws Exception {
        UUID id = createTodo("Use timestamp");
        Instant completionTime = Instant.parse("2024-12-30T12:00:00Z");
        mvc.perform(patch("/api/todos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                .content("{\"completedDateTime\":\"" + completionTime + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed").value(true));
        assertEquals(completionTime.toEpochMilli(), service.getTodo(id).getCompletedDateTime().getTime());

        mvc.perform(patch("/api/todos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                .content("{\"completedDateTime\":null}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed").value(false));
        assertNull(service.getTodo(id).getCompletedDateTime());
    }

    @Test
    void serverRenderedFormCanCompleteAndReopenATodo() throws Exception {
        UUID id = createTodo("Use form");
        mvc.perform(post("/update-refresh")
                .param("todoList[0].id", id.toString())
                .param("todoList[0].completed", "on")
                .param("todoList[0].completedOrig", "false"))
                .andExpect(status().isOk())
                .andExpect(model().attribute("todoListStatus", ""));
        assertNotNull(service.getTodo(id).getCompletedDateTime());

        mvc.perform(post("/update-refresh")
                .param("todoList[0].id", id.toString())
                .param("todoList[0].completedOrig", "true"))
                .andExpect(status().isOk())
                .andExpect(model().attribute("todoListStatus", ""));
        assertNull(service.getTodo(id).getCompletedDateTime());
    }

    private UUID createTodo(String text) {
        UUID id = service.createTodo(text).getId();
        createdIds.add(id);
        return id;
    }
}
