import { v4 as uuidv4 } from 'uuid';

const KEY = 'lvdbg:window-id';

export default function initWindowIdentifier(debugChannel, socketID) {
  const windowID = maybeSetWindowID();

  debugChannel.push('window-initialized', {
    window_id: windowID,
    socket_id: socketID,
  });
}

function maybeSetWindowID() {
  const windowID = sessionStorage.getItem(KEY);
  if (windowID) {
    return windowID;
  }

  const newWindowID = uuidv4();
  sessionStorage.setItem(KEY, newWindowID);
  return newWindowID;
}
