/**
 * Tour API — allows the client app to control the LiveDebugger tour UI.
 *
 * All actions are sent via the WebSocket debug channel to the debugger,
 * where the Tour JS hook applies them to the debugger UI.
 *
 * ## Actions
 *
 * - spotlight(target, dismiss) — dims everything except the target element
 * - highlight(target, dismiss) — outlines the target element
 * - clear() — removes all tour effects
 *
 * ## Dismiss modes
 *
 * - "click-anywhere" — clears on any click, no callback
 * - "click-target"   — clears only when user clicks the target element,
 *                       triggers "step-completed" callback
 *
 * ## Callbacks
 *
 * - onStepCompleted(fn) — called when user completes a "click-target" step
 * - onFetchCurrentStep(fn) — called when debugger requests the current step
 *                            (e.g. after page reload)
 *
 * ## Settings control
 *
 * - enableSettings() — unlocks settings toggles in debugger
 * - disableSettings() — locks settings toggles in debugger
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

function sendAction(action, target, dismiss) {
  if (!assertReady()) return;
  _channel.push('tour:action', { action, target, dismiss });
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
    sendAction('spotlight', target, dismiss);
  },

  highlight(target, dismiss = 'click-anywhere') {
    sendAction('highlight', target, dismiss);
  },

  clear() {
    sendAction('clear');
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
