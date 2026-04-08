import initDebugButton from './debug_button/debug_button';
import initDebugOptions from './debug_options/debug_options';
import { dispatchCustomEvent } from '../utils/dom';
import { isDebugButtonEnabled } from '../utils/meta';

export default function initDebugMenu(
  metaTag,
  liveDebuggerURL,
  debugChannel,
  shadowRoot
) {
  const debugButton = initDebugButton();
  const debugMenu = initDebugOptions({ liveDebuggerURL, debugChannel });
  let suppressOutsideClick = false;

  const suppressNext = () => {
    suppressOutsideClick = true;
    setTimeout(() => {
      suppressOutsideClick = false;
    }, 0);
  };

  debugButton.addEventListener('click', suppressNext, true);
  debugMenu.addEventListener('click', suppressNext, true);

  const mount = () => {
    shadowRoot.appendChild(debugButton);
    shadowRoot.appendChild(debugMenu);
  };

  const unmount = () => {
    debugButton.remove();
    debugMenu.remove();
  };

  if (isDebugButtonEnabled(metaTag)) mount();

  debugChannel.on('toggle-debug-button', ({ enabled }) => {
    if (enabled) {
      mount();
    } else {
      unmount();
    }
  });

  // Hide menu when clicking outside
  document.addEventListener('click', (event) => {
    const path = event.composedPath?.() ?? [event.target];
    const clickedInside =
      path.includes(debugButton) ||
      path.includes(debugMenu) ||
      path.some((node) => node?.getRootNode?.() === shadowRoot);

    if (suppressOutsideClick) return;

    if (!clickedInside) {
      dispatchCustomEvent('lvdbg:click-outside-debug-menu');
    }
  });

  return { debugButton, debugMenu };
}
