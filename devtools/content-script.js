window.addEventListener("click", (event) => {
  const componentId = event.target.closest("[data-phx-component]")?.dataset
    .phxComponent;

  chrome.runtime.sendMessage({ componentId: componentId });
});
