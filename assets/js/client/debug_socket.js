import { Socket } from 'phoenix';

function initDebugSocket(baseURL, sessionId) {
  const websocketURL = baseURL.replace(/^http/, 'ws') + '/client';

  const debugSocket = new Socket(websocketURL, {
    params: {
      sessionId: sessionId ? sessionId : 'embedded',
    },
  });

  debugSocket.connect();

  const debugChannel = debugSocket.channel(`client:${sessionId}`);

  debugChannel
    .join()
    .receive('ok', () => {
      console.log('LiveDebugger debug connection established!');
    })
    .receive('error', (resp) => {
      console.error(
        'LiveDebugger was unable to establish websocket debug connection! Browser features will not work:\n',
        resp
      );
    });

  return { debugSocket, debugChannel };
}

export { initDebugSocket };
