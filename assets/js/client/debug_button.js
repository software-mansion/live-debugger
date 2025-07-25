import {
  createDebugButton,
  initButtonEvents,
} from './debug_button_component.js';

import {
  createTooltipMenu,
  initTooltipEvents,
} from './debug_tooltip_component.js';

function initDebugButton(liveDebuggerURL) {
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

export { initDebugButton };
