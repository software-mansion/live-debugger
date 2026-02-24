// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

import initDebugMenu from './components/debug_menu';
import initHighlight from './services/highlight';
import initElementInspection from './services/inspect';
import initTooltip from './components/tooltip/tooltip';
import DebugSocket from './services/debug_socket';

import {
  getMetaTag,
  fetchLiveDebuggerBaseURL,
} from './utils/meta';

import {
  getLiveViewSocketIds,
  getMainLiveViewSocketId,
  createFingerprint,
  getWindowFingerprint,
} from './utils/dom';

const missingMetaTagMessage = `
      LiveDebugger meta tag not found!
      If you have recently bumped LiveDebugger version, please update your layout according to the instructions in the GitHub README.
      You can find it here: https://github.com/software-mansion/live-debugger#installation
      `;

window.document.addEventListener('DOMContentLoaded', async () => {
  // If meta tag is missing, then LiveDebugger is not configured correctly
  const metaTag = getMetaTag();
  if (!metaTag) throw new Error(missingMetaTagMessage);

  // If there are no LiveViews, then we have nothing to debug
  const lvSocketIds = getLiveViewSocketIds();
  if (lvSocketIds.length === 0) return;

  const baseURL = fetchLiveDebuggerBaseURL(metaTag);
  const mainSocketID = getMainLiveViewSocketId();
  const sessionURL = `${baseURL}/redirect/${mainSocketID}`;

  // Initialize debug socket
  const debugSocket = new DebugSocket(baseURL);

  try {
    const fingerprint = createFingerprint(lvSocketIds);
    await debugSocket.connect(fingerprint);

    // Send example client event
    debugSocket.sendClientEvent('ping', { ping: 'ping' });

    // Setup MutationObserver to watch for fingerprint changes
    setupFingerprintObserver(debugSocket, fingerprint);

    // Initialize other features
    const windowChannel = debugSocket.windowChannel;

    windowChannel.on('find-successor', () => {
      const mainSocketId = getMainLiveViewSocketId();
      const liveSocketIds = getLiveViewSocketIds();


      if (mainSocketId) {
        windowChannel.push('found-successor', { socket_id: mainSocketId });
      } else {
        windowChannel.push('found-successor', { socket_id: liveSocketIds[0] });
      }
    });
    initElementInspection(baseURL, windowChannel);
    initTooltip();
    initDebugMenu(metaTag, sessionURL, windowChannel);
    initHighlight(windowChannel);

    console.info(`LiveDebugger available at: ${baseURL}`);
  } catch (error) {
    console.error('Failed to initialize LiveDebugger:', error);
  }
});

function setupFingerprintObserver(debugSocket, initialFingerprint) {
  let lastFingerprint = initialFingerprint;
  const targetNode = document.body;
  const config = { childList: true, subtree: true };

  const observer = new MutationObserver(async () => {
    const currentFingerprint = getWindowFingerprint();

    if (currentFingerprint !== lastFingerprint) {
      console.log('Fingerprint changed:', currentFingerprint);
      const previousFingerprint = lastFingerprint;
      lastFingerprint = currentFingerprint;

      try {
        await debugSocket.updateFingerprint(currentFingerprint, previousFingerprint);
      } catch (error) {
        console.error('Failed to update fingerprint:', error);
      }
    }
  });

  observer.observe(targetNode, config);
}
