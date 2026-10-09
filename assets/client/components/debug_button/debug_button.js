import debugButtonHtml from './debug_button.html';
import { createElement, dispatchCustomEvent } from '../../utils/dom';

export default function initDebugButton() {
  const debugButton = createElement(debugButtonHtml);

  let isDragging = false;

  const onClick = () => {
    if (isDragging) {
      placeButton();
    } else {
      dispatchCustomEvent('lvdbg:debug-button-click', {
        detail: {
          buttonRect: debugButton.getBoundingClientRect(),
        },
      });
    }
  };

  const dragButton = () => {
    isDragging = true;
    debugButton.style.cursor = 'grabbing';
    document.addEventListener('mousemove', onMouseMove);
  };

  const placeButton = () => {
    isDragging = false;
    debugButton.style.cursor = 'pointer';
    document.removeEventListener('mousemove', onMouseMove);
  };

  const onMouseMove = (event) => {
    const buttonWidth = debugButton.offsetWidth;
    const buttonHeight = debugButton.offsetHeight;

    // Make sure the button doesn't overflow the viewport
    const maxLeft = window.innerWidth - buttonWidth;
    const maxTop = window.innerHeight - buttonHeight;

    const newLeft = Math.max(
      0,
      Math.min(event.clientX - buttonWidth / 2, maxLeft)
    );
    const newTop = Math.max(
      0,
      Math.min(event.clientY - buttonHeight / 2, maxTop)
    );

    debugButton.style.setProperty('left', `${newLeft}px`, 'important');
    debugButton.style.setProperty('top', `${newTop}px`, 'important');
    debugButton.style.setProperty('right', 'auto', 'important');
    debugButton.style.setProperty('bottom', 'auto', 'important');
  };

  const ensureButtonInViewport = () => {
    const buttonRect = debugButton.getBoundingClientRect();

    const isVisible =
      buttonRect.top >= 0 &&
      buttonRect.left >= 0 &&
      buttonRect.bottom <= window.innerHeight &&
      buttonRect.right <= window.innerWidth;

    if (!isVisible) {
      debugButton.style.left = '';
      debugButton.style.top = '';
      debugButton.style.right = '';
      debugButton.style.bottom = '';
    }
  };

  debugButton.addEventListener('click', onClick);
  document.addEventListener('lvdbg:move-button-click', dragButton);
  window.addEventListener('resize', () => ensureButtonInViewport());

  return debugButton;
}
