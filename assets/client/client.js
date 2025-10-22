// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import initDebugMenu from './components/debug_menu';
import initHighlight from './services/highlight';
import initDebugSocket from './services/debug_socket';
import initElementInspection from './services/inspect';
import initTooltip from './components/tooltip/tooltip';

import {
  getMetaTag,
  fetchLiveDebuggerBaseURL,
  fetchDebuggedSocketIDs,
  isDebugButtonEnabled,
  isHighlightingEnabled,
} from './utils/meta';

window.document.addEventListener('DOMContentLoaded', async () => {
  const metaTag = getMetaTag();
  const baseURL = fetchLiveDebuggerBaseURL(metaTag);
  let { mainSocketID, rootSocketIDs } = await fetchDebuggedSocketIDs();

  if (!mainSocketID) {
    [mainSocketID, ...rootSocketIDs] = rootSocketIDs;
  } else {
    rootSocketIDs = [];
  }

  if (mainSocketID) {
    const sessionURL = `${baseURL}/redirect/${mainSocketID}`;

    const { debugChannel } = initDebugSocket(
      baseURL,
      mainSocketID,
      rootSocketIDs
    );

    debugChannel.on('ping', (resp) => {
      console.log('Received ping', resp);
      debugChannel.push('pong', resp);
    });

    initElementInspection({ baseURL, debugChannel, socketID: mainSocketID });
    initTooltip();

    if (isDebugButtonEnabled(metaTag)) {
      initDebugMenu(sessionURL, debugChannel);
    }

    if (isHighlightingEnabled(metaTag)) {
      initHighlight(debugChannel);
    }
  }

  console.info(`LiveDebugger available at: ${baseURL}`);
});
