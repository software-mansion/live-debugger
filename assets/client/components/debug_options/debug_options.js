import debugOptionsHtml from './debug_options.html';
import { createElement, dispatchCustomEvent } from '../../utils/dom';

export default function initDebugOptions({ liveDebuggerURL, debugChannel }) {
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
    dispatchCustomEvent('lvdbg:move-button-click');
    hideDebugOptions();
  };

  const onNewTabButtonClick = () => {
    window.open(liveDebuggerURL, '_blank');
    hideDebugOptions();
  };

  const onInspectButtonClick = () => {
    dispatchCustomEvent('lvdbg:inspect-button-click');
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

  document.addEventListener('lvdbg:debug-button-click', onDebugButtonClick);
  document.addEventListener('lvdbg:click-outside-debug-menu', hideDebugOptions);

  debugChannel.on('inspect-mode-changed', hideDebugOptions);

  window.addEventListener('resize', () => {
    if (isVisible) {
      hideDebugOptions();
    }
  });

  return debugOptions;
}
