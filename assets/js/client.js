// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import { initDebugButton } from './client/debug_button';
import { initHighlight } from './client/highlight';
import { Socket } from 'phoenix';
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

  // Add LiveDebugger Socket

  const wsUrl = baseURL.replace(/^http/, 'ws') + '/client';

  const liveDebuggerSocket = new Socket(wsUrl, {
    params: { sessionId: getSessionId() ? getSessionId() : 'embedded' },
  });

  liveDebuggerSocket.connect();

  const liveDebuggerChannel = liveDebuggerSocket.channel('client');

  window.addEventListener('click', (event) => {
    if (channelJoined) {
      liveDebuggerChannel.push('client-message', {
        event: event.target,
        sessionId: getSessionId(),
      });
    }
  });

  liveDebuggerChannel.on('lvdbg-message', (payload) => {
    console.log('Received message from server:', payload);
  });

  liveDebuggerChannel
    .join()
    .receive('ok', (resp) => {
      console.log('Joined successfully', resp);
      channelJoined = true;
    })
    .receive('error', (resp) => {
      console.log('Unable to join', resp);
    });
});
