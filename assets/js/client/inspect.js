function handleEvent(event) {
  const componentId = event.target.closest('[data-phx-component]')?.dataset
    .phxComponent;

  console.log(componentId);
}

function initInspect() {
  window.addEventListener('click', handleEvent);
}

export default initInspect;
