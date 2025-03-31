// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import { initDebugButton } from './client/debug_button';
import { initHighlight } from './client/highlight';

// Fetch LiveDebugger URL
window.getLiveDebuggerURL = function () {
  return document
    .getElementById('live-debugger-scripts')
    .src.replace('/assets/live_debugger/client.js', '');
};

window.getSessionId = function () {
  return document.querySelector('[data-phx-main]').id;
};

document.addEventListener('DOMContentLoaded', function () {
  const baseURL = window.getLiveDebuggerURL();
  const sessionId = window.getSessionId();
  const URL = `${baseURL}/transport_pid/${sessionId}`;

  initDebugButton(URL);

  initHighlight();

  // Finalize
  console.info(`LiveDebugger available at: ${URL}`);
});
