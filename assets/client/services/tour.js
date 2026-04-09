/**
 * Tour API — allows the client app to control the LiveDebugger tour UI.
 *
 * All commands are sent as `tour:<command>` messages via the WebSocket channel.
 * The Channel routes all `tour:*` messages to the `client:tour:receive` PubSub topic.
 *
 * ## Message convention
 *
 * Each API call maps to a channel message:
 *   spotlight(target, dismiss)  → push("tour:spotlight", {target, dismiss})
 *   highlight(target, dismiss)  → push("tour:highlight", {target, dismiss})
 *   clear()                     → push("tour:clear", {})
 *   redirect(url, nextStep)     → push("tour:redirect", {url, then: nextStep})
 *   enableSettings()            → push("tour:settings-enabled", {})
 *   disableSettings()           → push("tour:settings-disabled", {})
 *
 * ## Callbacks
 *
 * - onStepCompleted(fn) — called when user completes a "click-target" step
 * - onFetchCurrentStep(fn) — called when debugger requests the current step
 */

let _channel = null;
let _stepCompletedCallback = null;
let _fetchCurrentStepCallback = null;

function assertReady() {
  if (!_channel) {
    console.warn('[LiveDebugger Tour] Not initialized. Tour API is unavailable.');
  }
  return !!_channel;
}

export function initTour(debugChannel) {
  _channel = debugChannel;

  debugChannel.on('step-completed', (payload) => {
    if (_stepCompletedCallback) _stepCompletedCallback(payload);
  });

  debugChannel.on('fetch-current-tour-step', (payload) => {
    if (_fetchCurrentStepCallback) _fetchCurrentStepCallback(payload);
  });
}

export const tour = {
  spotlight(target, dismiss = 'click-target') {
    if (!assertReady()) return;
    _channel.push('tour:spotlight', { target, dismiss });
  },

  highlight(target, dismiss = 'click-anywhere') {
    if (!assertReady()) return;
    _channel.push('tour:highlight', { target, dismiss });
  },

  clear() {
    if (!assertReady()) return;
    _channel.push('tour:clear', {});
  },

  redirect(url, nextStep = null) {
    if (!assertReady()) return;
    const payload = { url };
    if (nextStep) payload.then = nextStep;
    _channel.push('tour:redirect', payload);
  },

  enableSettings() {
    if (!assertReady()) return;
    _channel.push('tour:settings-enabled', {});
  },

  disableSettings() {
    if (!assertReady()) return;
    _channel.push('tour:settings-disabled', {});
  },

  onStepCompleted(fn) {
    _stepCompletedCallback = fn;
  },

  onFetchCurrentStep(fn) {
    _fetchCurrentStepCallback = fn;
  },
};
