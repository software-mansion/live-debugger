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

function debugButtonEnabled() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.hasAttribute('debug-button');
  } else {
    throw new Error('LiveDebugger meta tag not found');
  }
}

function getLiveDebuggerBaseURL() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.getAttribute('url');
  } else {
    throw new Error('LiveDebugger meta tag not found');
  }
}

function getSessionURL(baseURL) {
  const session_id = getSessionId();
  const session_path = session_id ? `transport_pid/${session_id}` : '';

  return `${baseURL}/${session_path}`;
}

window.getLiveDebuggerURL = function () {
  const baseURL = getLiveDebuggerBaseURL();
  const sessionURL = getSessionURL(baseURL);

  return sessionURL;
};

window.document.addEventListener('DOMContentLoaded', function () {
  const baseURL = getLiveDebuggerBaseURL();
  const sessionURL = getSessionURL(baseURL);

  if (debugButtonEnabled()) {
    initDebugButton(sessionURL);
  }

  initHighlight();

  // Finalize
  console.info(`LiveDebugger available at: ${baseURL}`);
});
