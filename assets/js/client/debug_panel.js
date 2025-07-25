import {
  createDebugButton,
  initButtonEvents,
} from './debug_panel/debug_button.js';

import {
  createTooltipMenu,
  initTooltipEvents,
} from './debug_panel/debug_menu.js';

function initDebugPanel(liveDebuggerURL) {
  const debugButton = createDebugButton(liveDebuggerURL);
  const tooltip = createTooltipMenu(liveDebuggerURL);

  document.body.appendChild(debugButton);
  document.body.appendChild(tooltip);

  // Initialize button events
  const buttonState = initButtonEvents(debugButton, tooltip);

  // Initialize tooltip events
  initTooltipEvents(tooltip, debugButton, buttonState, liveDebuggerURL);

  return { debugButton, tooltip, buttonState };
}

export { initDebugPanel };
