function handleInspect(sessionId, baseURL) {
  return function (event) {
    const componentId = event.target.closest('[data-phx-component]')?.dataset
      .phxComponent;

    const params = {
      sessionId: sessionId,
      componentId: componentId,
    };

    const url = `${baseURL}/inspect-element`;

    fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params),
    })
      .then((response) => response.json())
      .then((data) => console.log(data));
  };
}

function handleInspectOn(sessionId, baseURL) {
  window.addEventListener('click', handleInspect(sessionId, baseURL));
}

function handleInspectOff(sessionId, baseURL) {
  window.removeEventListener('click', handleInspect(sessionId, baseURL));
}

function initInspect(sessionId, baseURL) {
  window.addEventListener(
    'phx:inspect-on',
    handleInspectOn(sessionId, baseURL)
  );
  window.addEventListener(
    'phx:inspect-off',
    handleInspectOff(sessionId, baseURL)
  );
  handleInspectOn(sessionId, baseURL);
}

export default initInspect;
