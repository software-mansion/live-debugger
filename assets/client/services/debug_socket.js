import { v4 as uuidv4 } from 'uuid';

export default class DebugSocket {
  constructor(baseURL) {
    this.baseURL = baseURL;
    this.debugSocket = null;
    this.initChannel = null;
    this.windowChannel = null;
    this.windowId = this.getWindowId();
    this.isRegistered = false;
  }

  getWindowId() {
    if (window.name) {
      return window.name;
    }

    const newWindowId = uuidv4();
    window.name = newWindowId;
    return newWindowId;
  }

  async connect() {
    const websocketURL = this.baseURL.replace(/^http/, 'ws') + '/client';
    this.debugSocket = new window.Phoenix.Socket(websocketURL);
    this.debugSocket.connect();

    this.initChannel = this.debugSocket.channel('client:init');

    return new Promise((resolve, reject) => {
      this.initChannel
        .join()
        .receive('ok', () => {
          console.log('LiveDebugger debug connection established!');
          resolve();
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

  async register(fingerprint) {
    if (this.isRegistered) {
      throw new Error('Window is already registered');
    }

    return new Promise((resolve, reject) => {
      this.initChannel
        .push('register', { window_id: this.windowId, fingerprint })
        .receive('ok', () => {
          this.windowChannel = this.debugSocket.channel(`client:${this.windowId}`);

          this.windowChannel
            .join()
            .receive('ok', () => {
              this.isRegistered = true;
              console.log('Window registered successfully!');
              resolve(this.windowChannel);
            })
            .receive('error', (resp) => {
              console.error('Failed to join window channel:', resp);
              reject(new Error('Failed to join window channel'));
            });
        })
        .receive('error', (resp) => {
          console.error('Failed to register window:', resp);
          reject(new Error('Failed to register window'));
        });
    });
  }

  async updateFingerprint(fingerprint, previousFingerprint) {
    if (!this.isRegistered) {
      throw new Error('Window must be registered before updating fingerprint');
    }

    return new Promise((resolve, reject) => {
      this.initChannel
        .push('update_fingerprint', {
          window_id: this.windowId,
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
    if (!this.windowChannel || !this.isRegistered) {
      console.warn('Cannot send client event: window channel not ready');
      return;
    }

    this.windowChannel.push('client_event', { event, payload });
  }
}
