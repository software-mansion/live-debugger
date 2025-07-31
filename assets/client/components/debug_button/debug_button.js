import debugButtonHtml from './debug_button.html';
import { createElement } from '../../utils/dom';

export default function initDebugButton() {
  const debugButton = createElement(debugButtonHtml);

  let isDragging = false;

  const onClick = () => {
    if (isDragging) {
      placeButton();
    } else {
      const event = new CustomEvent('lvdbg:debug-button-click', {
        detail: {
          buttonRect: debugButton.getBoundingClientRect(),
        },
      });
      document.dispatchEvent(event);
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

    debugButton.style.left = `${newLeft}px`;
    debugButton.style.top = `${newTop}px`;
    debugButton.style.right = 'auto';
    debugButton.style.bottom = 'auto';
  };

  const ensureButtonInViewport = () => {
    const buttonRect = debugButton.getBoundingClientRect();

    const isVisible =
      buttonRect.top >= 0 &&
      buttonRect.left >= 0 &&
      buttonRect.bottom <= window.innerHeight &&
      buttonRect.right <= window.innerWidth;

    if (!isVisible) {
      debugButton.style.left = 'auto';
      debugButton.style.top = 'auto';
      debugButton.style.right = '20px';
      debugButton.style.bottom = '20px';
    }
  };

  debugButton.addEventListener('click', onClick);
  document.addEventListener('lvdbg:move-button-click', dragButton);
  window.addEventListener('resize', () => ensureButtonInViewport());

  return debugButton;
}
