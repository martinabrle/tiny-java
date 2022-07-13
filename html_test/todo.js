"use-strict";

function saveTodo() {
  let todoCreateFormTextInput = document.getElementById("todo-create-form-text-input");
  let newTodoText = todoCreateFormTextInput.value;
  if (newTodoText == undefined || newTodoText.trim() == "") {
    showTodoCreateFormMessage("error", "New Todo text should not be empty.", 10000);
    return;
  }
  //debug only addTodoToList({ id: 1, todoText: newTodoText, status: 'created on 21.2.3004'});

  showTodoCreateFormMessage("saving", "Saving the new Todo...");

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
            console.log(`Received '${response.status}', task has been saved, contining with parsing.`);
            try {
              let jsonTodo = JSON.parse(text);
              if (jsonTodo == null || jsonTodo.todoText === undefined || jsonTodo.todoText == null || jsonTodo.todoText === "") {
                throw "Empty task received from the server as a confirmation";
              }

              addTodoToList(jsonTodo);

              let todoMsgText = jsonTodo.todoText;
              if (todoMsgText.length > 5) todoMsgText = todoMsgText.substring(todoMsgText, 5) + "...";

              hideTodoCreateSection();
              showCommandBar();
              showTodosFormMessage("saved", "Task '" + todoMsgText + "' has beed saved.", 2000);
            } catch (ex) {
              //Unable to parse, but the task has been saved
              console.log(`An exception '${ex}' ocurred, but the task was most likely saved.`);
              showTodoCreateFormMessage("error", "Task has beed saved, but the server response is malformated. Try to refresh the page.", 20000);
            }
          })
          .catch((reason) => {
            //Server returned another error, reduce number of requests and wait longer
            if (repeats > 4) {
              console.log(`An exception '${reason}' ocurred will try again.`);
              scheduleCheckTodoAsyncSaved(trackingId, repeats - 4, 500);
            } else {
              console.log(`An exception '${reason}' ocurred, giving up.`);
              showTodoCreateFormMessage("error", "An error has occured while retrieving the task status. Please try saving the task again later.", 20000);
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
          console.log(`Received '${response.status}' and tried too many times already, giving up.`);
          showTodoCreateFormMessage("error", "An error has occured while saving the task. Please try again later.", 20000);
        }
      }
    })
    .catch((reason) => {
      console.log(`Exception '${reason}', occured, giving up.`);
      showTodoCreateFormMessage("error", "An error has occured while saving the task. Please try again later.", 20000);
    });
}

function hideTodoCreateFormMessage() {
  let messageBox = document.getElementById("todo-create-form-message-box");
  if (messageBox == undefined) {
    return;
  }
  messageBox.parentElement.removeChild(messageBox);
}

function onCloseTodoCreateFormMessageClicked(e) {
  e.preventDefault();
  hideTodoCreateFormMessage();
}

function showTodoCreateFormMessage(status, msgText, hideAfterMs) {
  if (todoCreateFormMessageTimer) {
    clearTimeout(todoCreateFormMessageTimer);
    todoCreateFormMessageTimer = 0;
  }

  let messageBox = document.getElementById("todo-create-form-message-box");
  if (messageBox == undefined) {
    let todoForm = document.getElementById("todo-create-form");
    let todoSaveButton = document.getElementById("todo-save-button");

    let messageBox = document.createElement("div");
    messageBox.setAttribute("id", "todo-create-form-message-box");
    messageBox.classList.add("message-box");
    messageBox.classList.add(status);

    let messageText = document.createElement("div");
    messageText.setAttribute("id", "todo-create-form-message-box-text");
    messageText.classList.add("message-text");

    messageText.appendChild(document.createTextNode(msgText));

    messageBox.appendChild(messageText);

    let closeButton = document.createElement("a");
    closeButton.setAttribute("href", "#");
    closeButton.classList.add("close-icon");

    let closeImg = document.createElement("img");
    closeImg.setAttribute("src", "cancel.svg");
    closeImg.setAttribute("title", "Clear");
    closeImg.setAttribute("alt", "Clear message");
    closeImg.classList.add("close-img");
    closeButton.appendChild(closeImg);
    closeButton.addEventListener("click", onCloseTodoCreateFormMessageClicked);
    messageBox.appendChild(closeButton);

    todoForm.insertBefore(messageBox, todoSaveButton);

    if (status === "saving") {
      let progressBar = document.createElement("progress");
      progressBar.setAttribute("id", "todo-create-form-message-box-progress-bar");
      progressBar.classList.add("progress-bar");
      todoForm.insertBefore(progressBar, todoSaveButton);
    }
  } else {
    document.getElementById("todo-create-form-message-box-text").innerText = msgText;

    if (messageBox.classList.contains(status)) return;

    if (messageBox.classList.contains("saving")) messageBox.classList.remove("saving");
    if (messageBox.classList.contains("saved")) messageBox.classList.remove("saved");
    if (messageBox.classList.contains("info")) messageBox.classList.remove("info");
    if (messageBox.classList.contains("none")) messageBox.classList.remove("none");
    if (messageBox.classList.contains("error")) messageBox.classList.remove("error");

    let progressBar = document.getElementById("todo-create-form-message-box-progress-bar");
    if (status === "saving") {
      if (progressBar == undefined) {
        let progressBar = document.createElement("progress");
        progressBar.setAttribute("id", "todo-create-form-message-box-progress-bar");
        progressBar.classList.add("progress-bar");
        let todoSaveButton = document.getElementById("todo-save-button");
        todoSaveButton.parentElement.insertBefore(progressBar, todoSaveButton);
      }
    } else if (progressBar != undefined) {
      progressBar.parentElement.removeChild(progressBar);
    }

    messageBox.classList.add(status);
  }

  if (hideAfterMs != undefined) {
    todoCreateFormMessageTimer = setTimeout(hideTodoCreateFormMessage, hideAfterMs);
  }
}

let todoCreateFormMessageTimer = undefined;

let hideMessageBoxTimers=[];

function showMessage(textElementId, messageBoxElementId, parentElementId, insertBeforeElementId, progressBarElementId, status, msgText, hideAfterMs) {
  if (hideMessageBoxTimers[messageBoxElementId] != undefined) {
    clearTimeout(hideMessageBoxTimers[messageBoxElementId]);
    hideMessageBoxTimers[messageBoxElementId] = undefined;
  }

  let messageBox = document.getElementById(messageBoxElementId);
  if (messageBox == undefined) {
    let parentElement = document.getElementById(parentElementId);
    let insertBeforeElement = undefined;
    if (insertBeforeElementId != undefined && insertBeforeElementId !== "") {
      insertBeforeElement = document.getElementById(insertBeforeElementId);
    }

    let messageBox = document.createElement("div");
    messageBox.setAttribute("id", messageBoxElementId);
    messageBox.classList.add("message-box");
    messageBox.classList.add(status);

    let messageText = document.createElement("div");
    messageText.setAttribute("id", textElementId);
    messageText.classList.add("message-text");

    messageText.appendChild(document.createTextNode(msgText));

    messageBox.appendChild(messageText);

    let closeButton = document.createElement("a");
    closeButton.setAttribute("href", "#");
    closeButton.classList.add("close-icon");

    let closeImg = document.createElement("img");
    closeImg.setAttribute("src", "cancel.svg");
    closeImg.setAttribute("title", "Clear");
    closeImg.setAttribute("alt", "Clear message");
    closeImg.classList.add("close-img");
    closeButton.appendChild(closeImg);
    closeButton.addEventListener("click", onCloseMessageBoxClicked);
    messageBox.appendChild(closeButton);

    if (insertBeforeElementId != undefined) {
      parentElement.insertBefore(messageBox, insertBeforeElement);
    } else {
      parentElement.append(messageBox);
    }
    if (progressBarElementId != undefined && status === "saving") {
      let progressBar = document.createElement("progress");
      progressBar.setAttribute("id", progressBarElementId);
      progressBar.classList.add("progress-bar");
      parentElement.insertBefore(progressBar, insertBeforeElement);
    }
  } else {
    let messageText = document.getElementById(textElementId)
    if (messageText == undefined) {
      messageText = document.createElement("div");
      messageText.setAttribute("id", textElementId);
      messageText.classList.add("message-text");
      messageText.appendChild(document.createTextNode(msgText));
    } else {
      messageText.innerText = msgText;
    }
    
    if (!messageText.classList.contains(status)) {
      if (messageBox.classList.contains("saving")) messageBox.classList.remove("saving");
      if (messageBox.classList.contains("saved")) messageBox.classList.remove("saved");
      if (messageBox.classList.contains("info")) messageBox.classList.remove("info");
      if (messageBox.classList.contains("none")) messageBox.classList.remove("none");
      if (messageBox.classList.contains("error")) messageBox.classList.remove("error");
      messageBox.classList.add(status);
    }
  
    let progressBar = document.getElementById(progressBarElementId);
    if (progressBar != undefined) {
      //Progress bar needs to be below the text
      if (progressBar.previousElementSibling == undefined || progressBar.previousElementSibling.id !== messageBox.id) {
        progressBar.parentElement.removeChild(progressBar);
        progressBar = undefined;
      }
    }

    if (status === "saving") {
      if (progressBar == undefined) {
        let progressBar = document.createElement("progress");
        progressBar.setAttribute("id", progressBarElementId);
        progressBar.classList.add("progress-bar");

        if (messageText.nextElementSibling != undefined) {
          messageText.parentElement.insertBefore(progressBar, messageText.nextElementSibling);
        } else {
          messageText.parentElement.appendChild(progressBar);
        }
      }
    } else if (progressBar != undefined) {
      progressBar.parentElement.removeChild(progressBar);
    }
  }
  if (hideMessageBoxTimers[messageBoxElementId] != undefined) {
    hideMessageBoxTimers[messageBoxElementId] = setTimeout(hideMessageBox, hideAfterMs, messageBoxElementId);
  }
}

function hideMessageBox(messageBoxElementId) {
  if (hideMessageBoxTimers[messageBoxElementId] != undefined) {
    clearTimeout(hideMessageBoxTimers[messageBoxElementId]);
    hideMessageBoxTimers[messageBoxElementId] = undefined;
  }

  let messageBox = document.getElementById(messageBoxElementId);
  if (messageBox != undefined) {
    messageBox.parentElement.removeChild(messageBox);
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
  newTodoStatusTextDivElement.appendChild(document.createTextNode(" - " + todo.status));
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
  console.log(`New Todo '${todo.id}' added successfully to the UL list of HTML LI elements.`);
}

function showTodoCreateSection() {
  let todoCreateSection = document.getElementById("todo-form");
  if (todoCreateSection != undefined) {
    return;
  }

  todoCreateSection = document.createElement("section");
  todoCreateSection.setAttribute("id", "todo-create");

  let todoCreateForm = document.createElement("div");
  todoCreateForm.setAttribute("id", "todo-create-form");
  todoCreateSection.appendChild(todoCreateForm);

  let todoCreateFormEntryArea = document.createElement("div");
  todoCreateFormEntryArea.setAttribute("class", "form-control");
  todoCreateForm.appendChild(todoCreateFormEntryArea);

  let todoCreateFormTextLabel = document.createElement("label");
  todoCreateFormTextLabel.setAttribute("id", "todo-create-form-text-label");
  todoCreateFormTextLabel.setAttribute("for", "todo-create-form-text-input");
  todoCreateFormTextLabel.appendChild(document.createTextNode("New task"));

  let todoCreateFormTextInput = document.createElement("input");
  todoCreateFormTextInput.setAttribute("type", "text");
  todoCreateFormTextInput.setAttribute("id", "todo-create-form-text-input");

  todoCreateFormEntryArea.appendChild(todoCreateFormTextInput);
  todoCreateFormEntryArea.insertBefore(todoCreateFormTextLabel, todoCreateFormTextInput);

  let submitButtonElememt = document.createElement("button");
  submitButtonElememt.setAttribute("type", "submit");
  submitButtonElememt.setAttribute("class", "button");
  submitButtonElememt.setAttribute("value", "create");
  submitButtonElememt.setAttribute("id", "todo-save-button");
  submitButtonElememt.appendChild(document.createTextNode("Save"));
  submitButtonElememt.addEventListener("click", onSaveConfirmButtonClick);
  todoCreateForm.appendChild(submitButtonElememt);

  todoCreateForm.appendChild(document.createTextNode(" "));

  let cancelButtonElememt = document.createElement("button");
  cancelButtonElememt.setAttribute("type", "submit");
  cancelButtonElememt.setAttribute("class", "button");
  cancelButtonElememt.setAttribute("value", "cancel");
  cancelButtonElememt.setAttribute("id", "todo-cancel-button");
  cancelButtonElememt.appendChild(document.createTextNode("Cancel"));
  cancelButtonElememt.addEventListener("click", onSaveCancelButtonClick);
  todoCreateForm.appendChild(cancelButtonElememt);

  let todosSection = document.getElementById("todos");
  todosSection.parentElement.insertBefore(todoCreateSection, todosSection);
}

function hideTodoCreateSection() {
  let todoCreateSection = document.getElementById("todo-create");
  if (todoCreateSection == undefined) {
    return;
  }
  todoCreateSection.parentElement.removeChild(todoCreateSection);
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
  showTodoCreateSection();
  hideCommandBar();
}

function onSaveConfirmButtonClick(e) {
  e.preventDefault();
  saveTodo();
}

function onSaveCancelButtonClick(e) {
  e.preventDefault();
  hideTodoCreateSection();
  showCommandBar();
}

function onRefreshUpdateButtonClick(e) {
  e.preventDefault();
  alert("not implemented yet");
}

function onDocumentLoad() {
  let addButton = document.getElementById("todos-create-button");
  if (addButton != undefined) {
    addButton.addEventListener("click", onAddTodoButtonClick);
  }
  let refreshUpdateButton = document.getElementById("todos-update-refresh-button");
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
