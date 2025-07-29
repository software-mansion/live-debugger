import bugIcon from './bug_icon.js';

function createDebugButton() {
  const debugButtonHtml = /*html*/ `
    <div id="debug-button">
      ${bugIcon}
    </div>
  `;

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = debugButtonHtml;
  return tempDiv.firstElementChild;
}

function createDebugMenu() {
  const tooltipHtml = /*html*/ `
    <div id="debug-tooltip">
      <div class="tooltip-option" >
        Open in new tab
      </div>
      <div class="tooltip-option">
        Inspect elements
      </div>
      <div class="tooltip-option">
        Move button
      </div>
    </div>
  `;

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = tooltipHtml;
  return tempDiv.firstElementChild;
}

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

    debugMenu.style.display = 'block';
    const menuRect = debugMenu.getBoundingClientRect();
    const menuWidth = menuRect.width;
    const menuHeight = menuRect.height;

    const scrollX = window.pageXOffset || document.documentElement.scrollLeft;
    const scrollY = window.pageYOffset || document.documentElement.scrollTop;

    // Check if the menu would overflow on the right
    if (buttonRect.right + menuWidth > window.innerWidth) {
      debugMenu.style.left = `${buttonRect.left + scrollX - menuWidth}px`;
    } else {
      debugMenu.style.left = `${buttonRect.right + scrollX}px`;
    }

    // Check if the menu would overflow on the bottom
    if (buttonRect.top + menuHeight > window.innerHeight) {
      debugMenu.style.top = `${buttonRect.bottom + scrollY - menuHeight}px`;
    } else {
      debugMenu.style.top = `${buttonRect.top + scrollY}px`;
    }

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

  // Hide menu and ensure button is in viewport when window is resized
  window.addEventListener('resize', () => {
    if (panelState.menuVisible) {
      hideMenu();
    }
    ensureButtonInViewport();
  });

  return { debugButton, debugMenu, panelState };
}

export { initDebugPanel };
