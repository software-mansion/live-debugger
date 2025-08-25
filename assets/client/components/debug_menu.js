import initDebugButton from './debug_button/debug_button';
import initDebugOptions from './debug_options/debug_options';
import { dispatchCustomEvent } from '../utils/dom';

export default function initDebugMenu(liveDebuggerURL, debugChannel) {
  const debugButton = initDebugButton();
  const debugMenu = initDebugOptions({ liveDebuggerURL, debugChannel });

  document.body.appendChild(debugButton);
  document.body.appendChild(debugMenu);

  // Hide menu when clicking outside
  document.addEventListener('click', (event) => {
    if (
      !debugButton.contains(event.target) &&
      !debugMenu.contains(event.target)
    ) {
      dispatchCustomEvent('lvdbg:click-outside-debug-menu');
    }
  });

  return { debugButton, debugMenu };
}
