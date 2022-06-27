"use strict";
let savingAsyncTimeoutId = -1;

function displayMessage(status, msgText) {
  document.getElementById("message-text").innerText = msgText;

  let messageBox = document.getElementById("message-box");

  if (messageBox.classList.contains(status)) return;

  if (messageBox.classList.contains("saving"))
    messageBox.classList.remove("saving");
  if (messageBox.classList.contains("saved"))
    messageBox.classList.remove("saved");
  if (messageBox.classList.contains("info"))
    messageBox.classList.remove("info");
  if (messageBox.classList.contains("none"))
    messageBox.classList.remove("none");

  messageBox.classList.add(status);
}

function scheduleCheckTodoAsyncSaved(trackingId, repeats, waitMS) {
  if (savingAsyncTimeoutId !== 0) {
    clearTimeout(savingAsyncTimeoutId);
    savingAsyncTimeoutId = 0;
  }

  savingAsyncTimeoutId = setTimeout(
    checkTodoAsyncSaved,
    waitMS,
    trackingId,
    repeats
  );
}

function addTodoToList(todo) {
  console.log(`Adding a task '${todo.id}' to the list of HTML DIV elements.`);

  let newTodoElem = document.createElement("div");
  newTodoElem.setAttribute("key", todo.id);
  newTodoElem.classList.add("todo-item");
  newTodoElem.classList.add("created");
  newTodoElem.innerHTML = `<div>${todo.createdDateTimeShortString}</div><div>${todo.todoText}</div><div>${todo.status}</div>`;

  let todoListElem = document.getElementById("todo-list");
  if (todoListElem.children.length > 0) {
    todoListElem.insertBefore(newTodoElem, todoListElem.children[0]);
  } else {
    todoListElem.appendChild(newTodoElem);
  }

  let allTodosFinishedElem = document.getElementById("todo-list-empty");
  if (allTodosFinishedElem != undefined) {
    console.log(`Removing the 'All todos finished' message.`);
    todoListElem.removeChild(allTodosFinishedElem);
  }
  console.log(
    `New Task '${todo.id}' added successfully to the list of HTML DIV elements.`
  );
}

function checkTodoAsyncSaved(id, repeats) {
  fetch(`/todos/${id}`)
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

              displayMessage(
                "saved",
                "Task '" + todoMsgText + "' has beed saved."
              );
            } catch (ex) {
              //Unable to parse, but the task has been saved
              console.log(
                `An exception '${ex}' ocurred, but the task was most likely saved.`
              );
              displayMessage(
                "error",
                "Task has beed saved, but the server response is malformated. Try to refresh the page."
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
              displayMessage(
                "error",
                "An error has occured while retrieving the task status. Please try again later."
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
          displayMessage(
            "error",
            "An error has occured while saving the task. Please try again later."
          );
        }
      }
    })
    .catch((reason) => {
      console.log(`Exception '${reason}', ccured, giving up.`);
      displayMessage(
        "error",
        "An error has occured while saving the task. Please try again later."
      );
    });
}

function onDocumentLoad() {
  if (
    typeof checkStatusAsync !== "undefined" &&
    typeof trackingId !== "undefined" &&
    checkStatusAsync === true
  ) {
    console.log(
      "Starting the attempt to asynchronously update the todo list without refreshing the page later on."
    );
    savingAsyncTimeoutId = scheduleCheckTodoAsyncSaved(trackingId, 50, 200);
  }
}

window.onload = onDocumentLoad;
