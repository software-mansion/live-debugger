export function createElement(html) {
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = html;
  return tempDiv.firstElementChild;
}

export function dispatchCustomEvent(event, payload = {}) {
  const customEvent = new CustomEvent(event, payload);
  document.dispatchEvent(customEvent);
}
