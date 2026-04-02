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

    const shadowHost = document.createElement('div');
    shadowHost.style.position = 'absolute';
    shadowHost.style.width = '0px';
    shadowHost.style.height = '0px';
    shadowHost.style.left = '0px';
    shadowHost.style.top = '0px';
    shadowHost.style.zIndex = '2147483647';
    document.body.appendChild(shadowHost);

    const shadowRoot = shadowHost.attachShadow({ mode: 'closed' });

    // Keep LiveDebugger styling fully encapsulated from user CSS.
    const cssLink = document.createElement('link');
    cssLink.rel = 'stylesheet';
    cssLink.href = `${baseURL}/assets/live_debugger/client.css`;
    shadowRoot.appendChild(cssLink);

    const { debugButton } = initDebugMenu(
      metaTag,
      sessionURL,
      debugChannel,
      shadowRoot
    );
    initElementInspection({
      baseURL,
      debugChannel,
      socketID: mainSocketID,
      debugButton,
    });
    initTooltip(shadowRoot);
    initHighlight(debugChannel, shadowRoot);
  }

  console.info(`LiveDebugger available at: ${baseURL}`);
});
