import { v4 as uuidv4 } from 'uuid';

export default function pushWindowInitialized(debugChannel, socketID) {
  const windowID = maybeSetWindowID();

  debugChannel.push('window-initialized', {
    window_id: windowID,
    socket_id: socketID,
  });
}

function maybeSetWindowID() {
  const windowID = window.name;
  if (windowID) {
    return windowID;
  }

  const newWindowID = uuidv4();
  window.name = newWindowID;
  return newWindowID;
}
