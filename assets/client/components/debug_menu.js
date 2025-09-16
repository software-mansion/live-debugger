import initDebugButton from './debug_button/debug_button';
import initDebugOptions from './debug_options/debug_options';
import { dispatchCustomEvent } from '../utils/dom';
import { isDebugButtonEnabled } from '../utils/meta';

export default function initDebugMenu(metaTag, liveDebuggerURL, debugChannel) {
  const debugButton = initDebugButton();
  const debugMenu = initDebugOptions({ liveDebuggerURL, debugChannel });

  if (isDebugButtonEnabled(metaTag)) {
    document.body.appendChild(debugButton);
    document.body.appendChild(debugMenu);
  }

  debugChannel.on('toggle-debug-button', ({ enabled }) => {
    if (enabled) {
      document.body.appendChild(debugButton);
      document.body.appendChild(debugMenu);
    } else {
      debugButton.remove();
      debugMenu.remove();
    }
  });

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
