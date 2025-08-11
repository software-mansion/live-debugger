import pushWindowInitialized from './window_identifier';

export default function initDebugSocket(baseURL, socketID) {
  const websocketURL = baseURL.replace(/^http/, 'ws') + '/client';

  const debugSocket = new window.Phoenix.Socket(websocketURL, {
    params: { socketID },
  });

  debugSocket.connect();

  const debugChannel = debugSocket.channel(`client:${socketID}`);

  debugChannel
    .join()
    .receive('ok', () => {
      pushWindowInitialized(debugChannel, socketID);
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
