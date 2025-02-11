// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

// Fetch LiveDebugger URL
const URL = document
  .getElementById("live-debugger-scripts")
  .src.replace("/assets/client.js", "");

// Debug button
document.addEventListener("DOMContentLoaded", function () {
  const session_id = document.querySelector("[data-phx-main]").id;
  const debugButtonHtml = /*html*/ `
      <div id="debug-button" style="
        position: fixed;
        height: 40px;
        width: 40px;
        padding-left: 5px;
        padding-right: 5px;
        border-radius: 10px;
        background-color: rgba(235, 235, 235, 0.8);
        display: flex;
        gap: 5px;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        bottom: 20px;
        right: 20px;
        cursor: grab;">
        <a href="${URL}/${session_id}" target="_blank">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 25px; height: 25px;">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M12 12.75c1.148 0 2.278.08 3.383.237 1.037.146 1.866.966 1.866 2.013 0 3.728-2.35 6.75-5.25 6.75S6.75 18.728 6.75 15c0-1.046.83-1.867 1.866-2.013A24.204 24.204 0 0 1 12 12.75Zm0 0c2.883 0 5.647.508 8.207 1.44a23.91 23.91 0 0 1-1.152 6.06M12 12.75c-2.883 0-5.647.508-8.208 1.44.125 2.104.52 4.136 1.153 6.06M12 12.75a2.25 2.25 0 0 0 2.248-2.354M12 12.75a2.25 2.25 0 0 1-2.248-2.354M12 8.25c.995 0 1.971-.08 2.922-.236.403-.066.74-.358.795-.762a3.778 3.778 0 0 0-.399-2.25M12 8.25c-.995 0-1.97-.08-2.922-.236-.402-.066-.74-.358-.795-.762a3.734 3.734 0 0 1 .4-2.253M12 8.25a2.25 2.25 0 0 0-2.248 2.146M12 8.25a2.25 2.25 0 0 1 2.248 2.146M8.683 5a6.032 6.032 0 0 1-1.155-1.002c.07-.63.27-1.222.574-1.747m.581 2.749A3.75 3.75 0 0 1 15.318 5m0 0c.427-.283.815-.62 1.155-.999a4.471 4.471 0 0 0-.575-1.752M4.921 6a24.048 24.048 0 0 0-.392 3.314c1.668.546 3.416.914 5.223 1.082M19.08 6c.205 1.08.337 2.187.392 3.314a23.882 23.882 0 0 1-5.223 1.082"
            />
          </svg>
        </a>
      </div>
  `;

  const tempDiv = document.createElement("div");
  tempDiv.innerHTML = debugButtonHtml;
  const debugButton = tempDiv.firstElementChild;
  document.body.appendChild(debugButton);

  let posX = 0,
    posY = 0,
    posXStart = 0,
    posYStart = 0;
  let dragging = false;

  const onMouseDown = (event) => {
    if (event.button !== 0) return;
    event.preventDefault();
    posXStart = event.clientX;
    posYStart = event.clientY;
    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseup", onMouseUp);
    debugButton.style.cursor = "grabbing";
    dragging = false;
  };

  const onMouseMove = (event) => {
    if (!event.clientX || !event.clientY) return;
    dragging = true;
    posX = posXStart - event.clientX;
    posY = posYStart - event.clientY;
    posXStart = event.clientX;
    posYStart = event.clientY;
    debugButton.style.top = debugButton.offsetTop - posY + "px";
    debugButton.style.left = debugButton.offsetLeft - posX + "px";
  };

  const onMouseUp = () => {
    document.removeEventListener("mousemove", onMouseMove);
    document.removeEventListener("mouseup", onMouseUp);
    debugButton.style.cursor = "grab";
  };

  const onClick = (event) => {
    if (dragging) {
      event.preventDefault();
      dragging = false;
    }
  };

  debugButton.addEventListener("mousedown", onMouseDown);
  debugButton.addEventListener("click", onClick);
});

// Finalize
console.info(`LiveDebugger available at: ${URL}`);
