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

function getLiveDebuggerBaseURL() {
  return document
    .getElementById('live-debugger-scripts')
    .src.replace('/assets/live_debugger/client.js', '');
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

  initDebugButton(sessionURL);

  initHighlight();

  // Finalize
  console.info(`LiveDebugger available at: ${baseURL}`);
});
