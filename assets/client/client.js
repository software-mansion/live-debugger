// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import initDebugMenu from './components/debug_menu';
import initHighlight from './services/highlight';
import initDebugSocket from './services/debug_socket';
import initElementInspection from './services/inspect';

import {
  getMetaTag,
  fetchLiveDebuggerBaseURL,
  fetchDebuggedSocketID,
  isRefactorEnabled,
  isDebugButtonEnabled,
  isHighlightingEnabled,
} from './utils/meta';

window.document.addEventListener('DOMContentLoaded', function () {
  const metaTag = getMetaTag();
  const baseURL = fetchLiveDebuggerBaseURL(metaTag);
  const socketID = fetchDebuggedSocketID();

  const sessionURL = `${baseURL}/redirect/${socketID}`;

  if (socketID) {
    if (isRefactorEnabled(metaTag)) {
      const { debugChannel } = initDebugSocket(baseURL, socketID);

      debugChannel.on('ping', (resp) => {
        console.log('Received ping', resp);
        debugChannel.push('pong', resp);
      });
    }

    if (isDebugButtonEnabled(metaTag)) {
      initDebugMenu(sessionURL);
    }

    if (isHighlightingEnabled(metaTag)) {
      initHighlight();
    }

    initElementInspection({ baseURL });
  }

  console.info(`LiveDebugger available at: ${baseURL}`);
});
