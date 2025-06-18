import { Socket } from 'phoenix';

function initLiveDebuggerSocket(baseURL, sessionId) {
  const wsUrl = baseURL.replace(/^http/, 'ws') + '/client';

  const liveDebuggerSocket = new Socket(wsUrl, {
    params: { sessionId: sessionId ? sessionId : 'embedded' },
  });

  liveDebuggerSocket.connect();

  const liveDebuggerChannel = liveDebuggerSocket.channel('client:' + sessionId);
  let channelJoined = false;

  liveDebuggerChannel
    .join()
    .receive('ok', (resp) => {
      console.log('Joined successfully', resp);
      channelJoined = true;
    })
    .receive('error', (resp) => {
      console.log('Unable to join', resp);
    });

  window.addEventListener('click', (event) => {
    if (channelJoined) {
      liveDebuggerChannel.push('client-message', {
        event: event.target,
        sessionId: sessionId,
      });
    }
  });

  return {
    liveDebuggerSocket: liveDebuggerSocket,
    liveDebuggerChannel: liveDebuggerChannel,
    channelJoined: channelJoined,
  };
}

export { initLiveDebuggerSocket };
