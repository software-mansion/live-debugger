import debugOptionsHtml from './debug_options.html';
import { createElement } from '../utils/dom';

export function initDebugOptions({ liveDebuggerURL }) {
  const debugOptions = createElement(debugOptionsHtml);

  let isVisible = false;

  const showDebugOptions = (debugButtonRect) => {
    debugOptions.style.display = 'block';

    const debugOptionsRect = debugOptions.getBoundingClientRect();
    const debugOptionsWidth = debugOptionsRect.width;
    const debugOptionsHeight = debugOptionsRect.height;

    const scrollX = window.pageXOffset || document.documentElement.scrollLeft;
    const scrollY = window.pageYOffset || document.documentElement.scrollTop;

    // Check if the debug options would overflow on the right
    if (debugButtonRect.right + debugOptionsWidth > window.innerWidth) {
      debugOptions.style.left = `${debugButtonRect.left + scrollX - debugOptionsWidth}px`;
    } else {
      debugOptions.style.left = `${debugButtonRect.right + scrollX}px`;
    }

    // Check if the debug options would overflow on the bottom
    if (debugButtonRect.top + debugOptionsHeight > window.innerHeight) {
      debugOptions.style.top = `${debugButtonRect.bottom + scrollY - debugOptionsHeight}px`;
    } else {
      debugOptions.style.top = `${debugButtonRect.top + scrollY}px`;
    }

    isVisible = true;
  };

  const hideDebugOptions = () => {
    debugOptions.style.display = 'none';
    isVisible = false;
  };

  const onDebugButtonClick = (event) => {
    const debugButtonRect = event.detail.buttonRect;
    if (isVisible) {
      hideDebugOptions();
    } else {
      showDebugOptions(debugButtonRect);
    }
  };

  const onMoveButtonClick = () => {
    const event = new CustomEvent('live-debugger-debug-button-move');
    document.dispatchEvent(event);
    hideDebugOptions();
  };

  const onNewTabButtonClick = () => {
    window.open(liveDebuggerURL, '_blank');
    hideDebugOptions();
  };

  const onInspectButtonClick = () => {
    hideDebugOptions();
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

  document.addEventListener(
    'live-debugger-debug-button-click',
    onDebugButtonClick
  );

  window.addEventListener('resize', () => {
    if (isVisible) {
      hideDebugOptions();
    }
  });

  return debugOptions;
}
