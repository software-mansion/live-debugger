import { v4 as uuidv4 } from 'uuid';

export default class DebugSocket {
  constructor(baseURL) {
    this.baseURL = baseURL;
    this.debugSocket = null;
    this.windowChannel = null;
    this.windowId = this.getWindowId();
  }

  getWindowId() {
    if (window.name) {
      return window.name;
    }

    const newWindowId = uuidv4();
    window.name = newWindowId;
    return newWindowId;
  }

  async connect(fingerprint) {
    const websocketURL = this.baseURL.replace(/^http/, 'ws') + '/client';
    this.debugSocket = new window.Phoenix.Socket(websocketURL);
    this.debugSocket.connect();

    this.windowChannel = this.debugSocket.channel(`client:${this.windowId}`, {
      fingerprint
    });

    return new Promise((resolve, reject) => {
      this.windowChannel
        .join()
        .receive('ok', () => {
          console.log('LiveDebugger debug connection established!');
          resolve(this.windowChannel);
        })
        .receive('error', (resp) => {
          console.error(
            'LiveDebugger was unable to establish websocket debug connection! Browser features will not work:\n',
            resp
          );
          reject(new Error('Failed to connect to debug socket'));
        });
    });
  }

  async updateFingerprint(fingerprint, previousFingerprint) {
    return new Promise((resolve, reject) => {
      this.windowChannel
        .push('update_fingerprint', {
          fingerprint,
          previous_fingerprint: previousFingerprint
        })
        .receive('ok', () => {
          console.log('Fingerprint updated successfully');
          resolve();
        })
        .receive('error', (resp) => {
          console.error('Failed to update fingerprint:', resp);
          reject(new Error('Failed to update fingerprint'));
        });
    });
  }

  sendClientEvent(event, payload = {}) {
    if (!this.windowChannel) {
      console.warn('Cannot send client event: window channel not ready');
      return;
    }

    this.windowChannel.push('client_event', { event, payload });
  }
}
