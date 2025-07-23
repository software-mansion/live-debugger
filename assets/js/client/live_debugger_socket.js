import { Socket } from 'phoenix';

function initLiveDebuggerSocket(baseURL, sessionId) {
  const websocketURL = baseURL.replace(/^http/, 'ws') + '/client';

  const liveDebuggerSocket = new Socket(websocketURL, {
    params: {
      sessionId: sessionId ? sessionId : 'embedded',
    },
  });

  liveDebuggerSocket.connect();

  const liveDebuggerChannel = liveDebuggerSocket.channel(`client:${sessionId}`);
  let joinedChannel = false;

  liveDebuggerChannel.on('trace', (trace) => {
    console.log('Received trace', trace);
  });

  liveDebuggerChannel
    .join()
    .receive('ok', (resp) => {
      console.log('Joined successfully', resp);
      joinedChannel = true;
    })
    .receive('error', (resp) => {
      console.log('Unable to join', resp);
    });

  liveDebuggerChannel.on('test', (resp) => {
    console.log('Received test', resp);
  });

  return {
    liveDebuggerSocket,
    liveDebuggerChannel,
    joinedChannel,
  };
}

export { initLiveDebuggerSocket };
