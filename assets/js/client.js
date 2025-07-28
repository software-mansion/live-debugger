// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import { initDebugButton } from './client/debug_button';
import { initHighlight } from './client/highlight';
import { initDebugSocket } from './client/debug_socket';

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

function refactorEnabled() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag.hasAttribute('refactor');
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

window.document.addEventListener('DOMContentLoaded', function () {
  const baseURL = getLiveDebuggerBaseURL();
  const sessionURL = getSessionURL(baseURL);
  const sessionId = getSessionId();

  if (refactorEnabled()) {
    if (sessionId) {
      const { debugChannel } = initDebugSocket(baseURL, sessionId);

      debugChannel.on('ping', (resp) => {
        console.log('Received ping', resp);
        debugChannel.push('pong', resp);
      });
    }
  }

  if (debugButtonEnabled()) {
    initDebugButton(sessionURL);
  }

  if (highlightingEnabled()) {
    initHighlight();
  }

  // Finalize
  console.info(`LiveDebugger available at: ${baseURL}`);
});
