"use-strict";

function saveTodo() {
  let newTodoInputTextElement = document.getElementById("new-todo-input-text");
  let newTodoText = newTodoInputTextElement.value;
  if (newTodoText == undefined || newTodoText.trim() == "") {
    showAddTaskFormMessage(
      "error",
      "New Todo text should not be empty.",
      10000
    );
    return;
  }
  //debug only addTodoToList({ id: 1, todoText: newTodoText, status: 'created on 21.2.3004'});

  showAddTaskFormMessage("saving", "Saving the new Todo...", 2000);

  fetch(`/todos/`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ todoText: newTodoText }),
  })
    .then((response) => {
      if (response.ok) {
        response
          .text()
          .then((text) => {
            console.log(
              `Received '${response.status}', task has been saved, contining with parsing.`
            );
            try {
              let jsonTodo = JSON.parse(text);
              if (
                jsonTodo == null ||
                jsonTodo.todoText === undefined ||
                jsonTodo.todoText == null ||
                jsonTodo.todoText === ""
              ) {
                throw "Empty task received from the server as a confirmation";
              }

              addTodoToList(jsonTodo);

              let todoMsgText = jsonTodo.todoText;
              if (todoMsgText.length > 5)
                todoMsgText = todoMsgText.substring(todoMsgText, 5) + "...";

              showAddTaskFormMessage(
                "saved",
                "Task '" + todoMsgText + "' has beed saved.",
                2000
              );
              hideAddTodoForm();
              showCommandBar();
            } catch (ex) {
              //Unable to parse, but the task has been saved
              console.log(
                `An exception '${ex}' ocurred, but the task was most likely saved.`
              );
              showAddTaskFormMessage(
                "error",
                "Task has beed saved, but the server response is malformated. Try to refresh the page.",
                20000
              );
            }
          })
          .catch((reason) => {
            //Server returned another error, reduce number of requests and wait longer
            if (repeats > 4) {
              console.log(`An exception '${reason}' ocurred will try again.`);
              scheduleCheckTodoAsyncSaved(trackingId, repeats - 4, 500);
            } else {
              console.log(`An exception '${reason}' ocurred, giving up.`);
              showAddTaskFormMessage(
                "error",
                "An error has occured while retrieving the task status. Please try again later.",
                20000
              );
            }
          });
      } else {
        let timedOut = true;
        //404 = Not in the database yet, everything else is server returned an error => reduce number of requests and wait longer
        if (response.status === 404 && repeats > 1) {
          console.log(`Received '${response.status}', will try again.`);
          scheduleCheckTodoAsyncSaved(trackingId, repeats - 1, 300);
          timedOut = false;
        } else if (response.status !== 404 && repeats > 4) {
          console.log(`Received '${response.status}', will try again.`);
          scheduleCheckTodoAsyncSaved(trackingId, repeats - 4, 300);
          timedOut = false;
        }
        if (timedOut) {
          console.log(
            `Received '${response.status}' and tried too many times already, giving up.`
          );
          showAddTaskFormMessage(
            "error",
            "An error has occured while saving the task. Please try again later.",
            20000
          );
        }
      }
    })
    .catch((reason) => {
      console.log(`Exception '${reason}', occured, giving up.`);
      showAddTaskFormMessage(
        "error",
        "An error has occured while saving the task. Please try again later.",
        20000
      );
    });
}

function hideAddTaskFormMessage() {
  let messageBox = document.getElementById("new-todo-form-message-box");
  if (messageBox == undefined) {
    return;
  }
  messageBox.parentElement.removeChild(messageBox);
}

function onCloseAddTaskFormMessageCloseClicked(e) {
  e.preventDefault();
  hideAddTaskFormMessage();
}
let messageHidingTimer = 0;

function showAddTaskFormMessage(status, msgText, hideAfterMs) {
  if (messageHidingTimer) {
    clearTimeout(messageHidingTimer);
    messageHidingTimer = 0;
  }

  let messageBox = document.getElementById("new-todo-form-message-box");
  if (messageBox == undefined) {
    let newTodoForm = document.getElementById("todo-new-todo-form");
    let todoSaveButton = document.getElementById("todo-save-button");

    let messageBox = document.createElement("div");
    messageBox.setAttribute("id", "new-todo-form-message-box");
    messageBox.classList.add("message-box");
    messageBox.classList.add(status);

    let messageText = document.createElement("div");
    messageText.setAttribute("id", "new-todo-form-message-text");
    messageText.classList.add("message-text");

    messageText.appendChild(document.createTextNode(msgText));

    messageBox.appendChild(messageText);

    let closeButton = document.createElement("button");
    closeButton.setAttribute("type", "submit");
    closeButton.setAttribute("action", "/close-msg-box");
    closeButton.setAttribute("id", "todo-close-msg-box-todo-list-button");
    closeButton.classList.add("close-icon");

    let closeImg = document.createElement("img");
    closeImg.setAttribute("src", "cancel.svg");
    closeImg.setAttribute("title", "Clear");
    closeImg.setAttribute("alt", "Clear message");
    closeImg.classList.add("close-img");
    closeButton.appendChild(closeImg);
    closeButton.addEventListener(
      "click",
      onCloseAddTaskFormMessageCloseClicked
    );
    messageBox.appendChild(closeButton);

    newTodoForm.insertBefore(messageBox, todoSaveButton);

    if (status === "saving") {
      let progressBar = document.createElement("progress");
      progressBar.setAttribute("id", "new-todo-form-message-box-progress-bar");
      progressBar.classList.add("new-todo-progress-bar");
      newTodoForm.insertBefore(progressBar, todoSaveButton);
    }
  } else {
    document.getElementById("new-todo-form-message-text").innerText = msgText;

    if (messageBox.classList.contains(status)) return;

    if (messageBox.classList.contains("saving"))
      messageBox.classList.remove("saving");
    if (messageBox.classList.contains("saved"))
      messageBox.classList.remove("saved");
    if (messageBox.classList.contains("info"))
      messageBox.classList.remove("info");
    if (messageBox.classList.contains("none"))
      messageBox.classList.remove("none");
    if (messageBox.classList.contains("error"))
      messageBox.classList.remove("error");

    let progressBar = document.getElementById(
      "new-todo-form-message-box-progress-bar"
    );
    if (status === "saving") {
      if (progressBar == undefined) {
        let progressBar = document.createElement("progress");
        progressBar.setAttribute(
          "id",
          "new-todo-form-message-box-progress-bar"
        );
        progressBar.classList.add("new-todo-progress-bar");
        let todoSaveButton = document.getElementById("todo-save-button");
        todoSaveButton.parentElement.insertBefore(progressBar, todoSaveButton);
      }
    } else if (progressBar != undefined) {
      progressBar.parentElement.removeChild(progressBar);
    }

    messageBox.classList.add(status);
  }

  if (hideAfterMs != undefined) {
    messageHidingTimer = setTimeout(hideAddTaskFormMessage, hideAfterMs);
  }
}

function addTodoToList(todo) {
  console.log(`Adding a todo '${todo.id}' to the UL list of HTML LI elements.`);

  let newTodoElement = document.createElement("li");
  newTodoElement.setAttribute("key", todo.id);
  newTodoElement.classList.add("todo-item");
  newTodoElement.classList.add("created");

  let newTodoCompleteCheckboxElement = document.createElement("input");
  newTodoCompleteCheckboxElement.setAttribute("type", "checkbox");
  newTodoCompleteCheckboxElement.setAttribute("class", "complete-checkbox");
  newTodoCompleteCheckboxElement.setAttribute("id", `completed-${todo.id}`);
  newTodoElement.appendChild(newTodoCompleteCheckboxElement);

  newTodoElement.appendChild(document.createTextNode(todo.todoText));

  let newTodoStatusTextDivElement = document.createElement("div");
  newTodoStatusTextDivElement.classList.add("todo-status");
  newTodoStatusTextDivElement.appendChild(
    document.createTextNode(" - " + todo.status)
  );
  newTodoElement.appendChild(newTodoStatusTextDivElement);

  let todoListElement = document.getElementById("todo-list");
  if (todoListElement.children.length > 0) {
    todoListElement.insertBefore(newTodoElement, todoListElement.children[0]);
  } else {
    todoListElement.appendChild(newTodoElemelement);
  }

  let allTodosFinishedElement = document.getElementById("todo-list-empty");
  if (allTodosFinishedElement != undefined) {
    console.log(`Removing the 'All todos finished' message.`);
    todoListElement.removeChild(allTodosFinishedElement);
  }
  console.log(
    `New Todo '${todo.id}' added successfully to the UL list of HTML LI elements.`
  );
}

function showAddTodoForm() {
  let localTodoForm = document.getElementById("todo-form");
  if (localTodoForm != undefined) {
    return;
  }

  let addTodoSectionElememt = document.createElement("section");
  addTodoSectionElememt.setAttribute("id", "todo-form");

  let formElememt = document.createElement("div");
  formElememt.setAttribute("id", "todo-new-todo-form");
  addTodoSectionElememt.appendChild(formElememt);

  let formControlDivElement = document.createElement("div");
  formControlDivElement.setAttribute("class", "form-control");
  formElememt.appendChild(formControlDivElement);

  let labelElememt = document.createElement("label");
  labelElememt.setAttribute("id", "todo-label");
  labelElememt.setAttribute("for", "new-todo-input-text");
  labelElememt.appendChild(document.createTextNode("New task"));

  let inputTextElememt = document.createElement("input");
  inputTextElememt.setAttribute("type", "text");
  inputTextElememt.setAttribute("id", "new-todo-input-text");

  formControlDivElement.appendChild(inputTextElememt);
  formControlDivElement.insertBefore(labelElememt, inputTextElememt);

  let submitButtonElememt = document.createElement("button");
  submitButtonElememt.setAttribute("type", "submit");
  submitButtonElememt.setAttribute("class", "button");
  submitButtonElememt.setAttribute("value", "create");
  submitButtonElememt.setAttribute("id", "todo-save-button");
  submitButtonElememt.appendChild(document.createTextNode("Save"));
  submitButtonElememt.addEventListener("click", onSaveConfirmButtonClick);
  formElememt.appendChild(submitButtonElememt);

  formElememt.appendChild(document.createTextNode(" "));

  let cancelButtonElememt = document.createElement("button");
  cancelButtonElememt.setAttribute("type", "submit");
  cancelButtonElememt.setAttribute("class", "button");
  cancelButtonElememt.setAttribute("value", "cancel");
  cancelButtonElememt.setAttribute("id", "todo-cancel-button");
  cancelButtonElememt.appendChild(document.createTextNode("Cancel"));
  cancelButtonElememt.addEventListener("click", onSaveCancelButtonClick);
  formElememt.appendChild(cancelButtonElememt);

  let todosSectionElement = document.getElementById("todos");
  todosSectionElement.parentElement.insertBefore(
    addTodoSectionElememt,
    todosSectionElement
  );
}

function hideAddTodoForm() {
  let addTodoSectionElememt = document.getElementById("todo-form");
  if (addTodoSectionElememt == undefined) {
    return;
  }
  addTodoSectionElememt.parentElement.removeChild(addTodoSectionElememt);
}

function showCommandBar() {
  let commandBar = document.getElementById("todos-command-bar");
  if (commandBar != undefined) {
    commandBar.style.display = "unset";
  }
}

function hideCommandBar() {
  let commandBar = document.getElementById("todos-command-bar");
  if (commandBar != undefined) {
    commandBar.style.display = "none";
  }
}

function onAddTodoButtonClick(e) {
  e.preventDefault();
  showAddTodoForm();
  hideCommandBar();
}

function onSaveConfirmButtonClick(e) {
  e.preventDefault();
  saveTodo();
}

function onSaveCancelButtonClick(e) {
  e.preventDefault();
  hideAddTodoForm();
  showCommandBar();
}

function onRefreshUpdateButtonClick(e) {
  e.preventDefault();
  alert("not implemented yet");
}

function onDocumentLoad() {
  let addButton = document.getElementById("todo-show-form-button");
  if (addButton != undefined) {
    addButton.addEventListener("click", onAddTodoButtonClick);
  }
  let refreshUpdateButton = document.getElementById(
    "todo-update-refresh-todos-button"
  );
  if (refreshUpdateButton != undefined) {
    refreshUpdateButton.addEventListener("click", onRefreshUpdateButtonClick);
  }

  let cancelButton = document.getElementById("todo-cancel-button");
  if (cancelButton != undefined) {
    cancelButton.addEventListener("click", onSaveCancelButtonClick);
  }
  let saveConfirmButton = document.getElementById("todo-save-button");
  if (saveConfirmButton != undefined) {
    saveConfirmButton.addEventListener("click", onSaveConfirmButtonClick);
  }
}

window.onload = onDocumentLoad;
