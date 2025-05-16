// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import { initDebugButton } from './client/debug_button';
import { initHighlight } from './client/highlight';

// Fetch LiveDebugger URL
function getSessionId() {
  let el;
  if ((el = document.querySelector('[data-phx-main]'))) {
    return el.id;
  }
  if ((el = document.querySelector('[id^="phx-"]'))) {
    return el.id;
  }
  if ((el = document.querySelector('[data-phx-root-id]'))) {
    return el.getAttribute('data-phx-root-id');
  }
}

function handleMetaTagError() {
  const message = `
  LiveDebugger meta tag not found!
  If you have recently bumped LiveDebugger version, please update your layout according to the instructions in the GitHub README.
  You can find it here: https://github.com/software-mansion/live-debugger#installation
  `;

  throw new Error(message);
}

function debugButtonEnabled() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.hasAttribute('debug-button');
  } else {
    handleMetaTagError();
  }
}

function highlightingEnabled() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.hasAttribute('highlighting');
  }
}

function getLiveDebuggerBaseURL() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.getAttribute('url');
  } else {
    handleMetaTagError();
  }
}

function getSessionURL(baseURL) {
  const session_id = getSessionId();
  const session_path = session_id ? `redirect/${session_id}` : '';

  return `${baseURL}/${session_path}`;
}

function uuidv4() {
  return '10000000-1000-4000-8000-100000000000'.replace(/[018]/g, (c) =>
    (
      +c ^
      (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (+c / 4)))
    ).toString(16)
  );
}

if (!sessionStorage.getItem('live-debugger-window-id')) {
  sessionStorage.setItem('live-debugger-window-id', uuidv4());
}

window.document.addEventListener('DOMContentLoaded', function () {
  const baseURL = getLiveDebuggerBaseURL();
  const sessionURL = getSessionURL(baseURL);

  if (debugButtonEnabled()) {
    initDebugButton(sessionURL);
  }

  if (highlightingEnabled()) {
    initHighlight();
  }

  // Finalize
  console.info(`LiveDebugger available at: ${baseURL}`);
});
