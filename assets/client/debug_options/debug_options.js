import debugOptionsHtml from './debug_options.html';
import { createElement } from '../utils/dom';

export function initDebugOptions({ liveDebuggerURL }) {
  const debugOptions = createElement(debugOptionsHtml);

  let isVisible = false;

  const showMenu = (debugButtonRect) => {
    debugOptions.style.display = 'block';

    const menuRect = debugOptions.getBoundingClientRect();
    const menuWidth = menuRect.width;
    const menuHeight = menuRect.height;

    const scrollX = window.pageXOffset || document.documentElement.scrollLeft;
    const scrollY = window.pageYOffset || document.documentElement.scrollTop;

    // Check if the menu would overflow on the right
    if (debugButtonRect.right + menuWidth > window.innerWidth) {
      debugOptions.style.left = `${debugButtonRect.left + scrollX - menuWidth}px`;
    } else {
      debugOptions.style.left = `${debugButtonRect.right + scrollX}px`;
    }

    // Check if the menu would overflow on the bottom
    if (debugButtonRect.top + menuHeight > window.innerHeight) {
      debugOptions.style.top = `${debugButtonRect.bottom + scrollY - menuHeight}px`;
    } else {
      debugOptions.style.top = `${debugButtonRect.top + scrollY}px`;
    }

    isVisible = true;
  };

  const hideMenu = () => {
    debugOptions.style.display = 'none';
    isVisible = false;
  };

  const onDebugButtonClick = (event) => {
    const debugButtonRect = event.detail.buttonRect;
    if (isVisible) {
      hideMenu();
    } else {
      showMenu(debugButtonRect);
    }
  };

  document.addEventListener(
    'live-debugger-debug-button-click',
    onDebugButtonClick
  );

  window.addEventListener('resize', () => {
    if (isVisible) {
      hideMenu();
    }
  });

  const onMoveButtonClick = () => {
    const event = new CustomEvent('live-debugger-debug-button-move');
    document.dispatchEvent(event);
    hideMenu();
  };

  const onNewTabButtonClick = () => {
    window.open(liveDebuggerURL, '_blank');
    hideMenu();
  };

  const onInspectButtonClick = () => {
    hideMenu();
  };

  debugOptions
    .querySelector('#live-debugger-debug-tooltip-open-in-new-tab')
    .addEventListener('click', onNewTabButtonClick);

  debugOptions
    .querySelector('#live-debugger-debug-tooltip-inspect-elements')
    .addEventListener('click', onInspectButtonClick);

  debugOptions
    .querySelector('#live-debugger-debug-tooltip-move-button')
    .addEventListener('click', onMoveButtonClick);

  return debugOptions;
}
