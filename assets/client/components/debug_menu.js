import initDebugButton from './debug_button/debug_button';
import initDebugOptions from './debug_options/debug_options';
import { dispatchCustomEvent } from '../utils/dom';
import { isDebugButtonEnabled } from '../utils/meta';

export default function initDebugMenu(metaTag, liveDebuggerURL, debugChannel) {
  const debugButton = initDebugButton();
  const debugMenu = initDebugOptions({ liveDebuggerURL, debugChannel });

  let debugButtonEnabled = isDebugButtonEnabled(metaTag);

  if (debugButtonEnabled) {
    document.body.appendChild(debugButton);
    document.body.appendChild(debugMenu);
  }

  debugChannel.on('toggle-debug-button', (_payload) => {
    if (debugButtonEnabled) {
      debugButtonEnabled = false;
      debugButton.remove();
      debugMenu.remove();
    } else {
      debugButtonEnabled = true;
      document.body.appendChild(debugButton);
      document.body.appendChild(debugMenu);
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
