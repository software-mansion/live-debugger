import { createDebugButton } from './debug_panel/debug_button.js';
import { createTooltipMenu } from './debug_panel/debug_menu.js';

function initDebugPanel(liveDebuggerURL) {
  const debugButton = createDebugButton();
  const tooltip = createTooltipMenu();

  document.body.appendChild(debugButton);
  document.body.appendChild(tooltip);

  // Panel state
  const panelState = {
    isDragging: false,
    tooltipVisible: false,
  };

  // Button event handlers
  const onButtonClick = () => {
    if (panelState.isDragging) {
      placeButton();
    } else {
      if (panelState.tooltipVisible) {
        hideTooltip();
      } else {
        showTooltip();
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

  // Tooltip event handlers
  const showTooltip = () => {
    const buttonRect = debugButton.getBoundingClientRect();
    const tooltipWidth = 160;
    const tooltipHeight = 120;

    // Check if the tooltip would overflow on the right
    if (buttonRect.right + tooltipWidth > window.innerWidth) {
      tooltip.style.left = `${buttonRect.left - tooltipWidth}px`;
    } else {
      tooltip.style.left = `${buttonRect.right}px`;
    }

    // Check if the tooltip would overflow on the bottom
    if (buttonRect.top + tooltipHeight > window.innerHeight) {
      tooltip.style.top = `${buttonRect.bottom - tooltipHeight}px`;
    } else {
      tooltip.style.top = `${buttonRect.top}px`;
    }

    tooltip.style.display = 'block';
    panelState.tooltipVisible = true;
  };

  const hideTooltip = () => {
    tooltip.style.display = 'none';
    panelState.tooltipVisible = false;
  };

  // Menu option handlers
  const handleOpenInNewTab = () => {
    window.open(liveDebuggerURL, '_blank');
    hideTooltip();
  };

  const handleInspectMode = () => {
    console.log('Inspect mode clicked');
    hideTooltip();
  };

  const handleMove = () => {
    startDragging();
    hideTooltip();
  };

  // Setup event listeners
  debugButton.addEventListener('click', onButtonClick);

  // Menu option clicks
  const tooltipOptions = tooltip.querySelectorAll('.tooltip-option');
  tooltipOptions[0].addEventListener('click', handleOpenInNewTab);
  tooltipOptions[1].addEventListener('click', handleInspectMode);
  tooltipOptions[2].addEventListener('click', handleMove);

  // Hide tooltip when clicking outside
  document.addEventListener('click', (event) => {
    if (
      !debugButton.contains(event.target) &&
      !tooltip.contains(event.target)
    ) {
      hideTooltip();
    }
  });

  // Hide tooltip when window is resized
  window.addEventListener('resize', () => {
    if (panelState.tooltipVisible) {
      hideTooltip();
    }
  });

  return { debugButton, tooltip, panelState };
}

export { initDebugPanel };
