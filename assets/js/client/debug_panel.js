import { createDebugButton } from './debug_panel/debug_button.js';
import { createDebugMenu } from './debug_panel/debug_menu.js';

function initDebugPanel(liveDebuggerURL) {
  const debugButton = createDebugButton();
  const debugMenu = createDebugMenu();

  document.body.appendChild(debugButton);
  document.body.appendChild(debugMenu);

  // Panel state
  const panelState = {
    isDragging: false,
    menuVisible: false,
    isInspecting: false,
  };

  // Button event handlers
  const onButtonClick = () => {
    if (panelState.isDragging) {
      placeButton();
    } else {
      if (panelState.menuVisible) {
        hideMenu();
      } else {
        showMenu();
      }
    }
  };

  const startDragging = () => {
    panelState.isDragging = true;
    debugButton.style.cursor = 'grabbing';
    document.addEventListener('mousemove', onMouseMove);
  };

  const placeButton = () => {
    panelState.isDragging = false;
    debugButton.style.cursor = 'pointer';
    document.removeEventListener('mousemove', onMouseMove);
  };

  const onMouseMove = (event) => {
    if (panelState.isDragging) {
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
    }
  };

  const showMenu = () => {
    const buttonRect = debugButton.getBoundingClientRect();
    const menuWidth = 160;
    const menuHeight = 120;

    // Check if the menu would overflow on the right
    if (buttonRect.right + menuWidth > window.innerWidth) {
      debugMenu.style.left = `${buttonRect.left - menuWidth}px`;
    } else {
      debugMenu.style.left = `${buttonRect.right}px`;
    }

    // Check if the menu would overflow on the bottom
    if (buttonRect.top + menuHeight > window.innerHeight) {
      debugMenu.style.top = `${buttonRect.bottom - menuHeight}px`;
    } else {
      debugMenu.style.top = `${buttonRect.top}px`;
    }

    debugMenu.style.display = 'block';
    panelState.menuVisible = true;
  };

  const hideMenu = () => {
    debugMenu.style.display = 'none';
    panelState.menuVisible = false;
  };

  const handleOpenInNewTab = () => {
    window.open(liveDebuggerURL, '_blank');
    hideMenu();
  };

  const handleInspectMode = (event) => {
    event.stopPropagation();
    panelState.isInspecting = true;
    document.body.style.cursor = 'crosshair';
    hideMenu();
  };

  const handleMove = () => {
    startDragging();
    hideMenu();
  };

  // Setup event listeners
  debugButton.addEventListener('click', onButtonClick);

  // Menu option clicks
  const menuOptions = debugMenu.querySelectorAll('.tooltip-option');
  menuOptions[0].addEventListener('click', handleOpenInNewTab);
  menuOptions[1].addEventListener('click', handleInspectMode);
  menuOptions[2].addEventListener('click', handleMove);

  // Hide menu when clicking outside
  document.addEventListener('click', (event) => {
    if (
      !debugButton.contains(event.target) &&
      !debugMenu.contains(event.target)
    ) {
      hideMenu();
    }

    if (panelState.isInspecting) {
      panelState.isInspecting = false;
      document.body.style.cursor = 'default';
    }
  });

  // Hide menu when window is resized
  window.addEventListener('resize', () => {
    if (panelState.menuVisible) {
      hideMenu();
    }
  });

  return { debugButton, debugMenu, panelState };
}

export { initDebugPanel };
