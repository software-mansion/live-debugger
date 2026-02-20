export function createElement(html) {
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = html;
  return tempDiv.firstElementChild;
}

export function dispatchCustomEvent(event, payload = {}) {
  const customEvent = new CustomEvent(event, payload);
  document.dispatchEvent(customEvent);
}

export function getLiveViewSocketIds() {
  return Array.from(document.querySelectorAll('[data-phx-session]')).map(el => el.id);
}

export function getMainLiveViewSocketId() {
  return document.querySelector('[data-phx-main]')?.id;
}

export function createFingerprint(socketIds) {
  return socketIds.sort().join(';');
}

export function getWindowFingerprint() {
  const socketIds = getLiveViewSocketIds();
  return createFingerprint(socketIds);
}