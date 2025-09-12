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

    // Check if the debug options would overflow on the right
    if (debugButtonRect.right + debugOptionsWidth > window.innerWidth) {
      debugOptions.style.left = `${debugButtonRect.left - debugOptionsWidth}px`;
    } else {
      debugOptions.style.left = `${debugButtonRect.right}px`;
    }

    // Check if the debug options would overflow on the bottom
    if (debugButtonRect.top + debugOptionsHeight > window.innerHeight) {
      debugOptions.style.top = `${debugButtonRect.bottom - debugOptionsHeight}px`;
    } else {
      debugOptions.style.top = `${debugButtonRect.top}px`;
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

  const onNewTabButtonClick = () => {
    window.open(liveDebuggerURL, '_blank');
    hideDebugOptions();
  };

  const onInspectButtonClick = () => {
    dispatchCustomEvent('lvdbg:inspect-button-click');
    hideDebugOptions();
  };

  const onMoveButtonClick = () => {
    dispatchCustomEvent('lvdbg:move-button-click');
    hideDebugOptions();
  };

  const onRemoveButtonClick = () => {
    dispatchCustomEvent('lvdbg:remove-button-click');
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

  debugOptions
    .querySelector('#live-debugger-debug-tooltip-remove-button')
    .addEventListener('click', onRemoveButtonClick);

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
