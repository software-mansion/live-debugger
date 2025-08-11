const tooltipID = 'live-debugger-tooltip';

function createTooltip(data) {
  removeTooltip();

  const tooltip = document.createElement('div');
  tooltip.id = tooltipID;
  tooltip.className = 'live-debugger-inspection-tooltip';

  // Create tooltip content - just module name
  const content = document.createElement('div');
  content.className = 'live-debugger-tooltip-content';
  content.textContent = data.module || 'Element';

  tooltip.appendChild(content);
  document.body.appendChild(tooltip);

  return tooltip;
}

function positionTooltip(tooltip, highlightElement) {
  if (!highlightElement || !tooltip) return;

  const highlightRect = highlightElement.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  // Start with position above the highlight element
  let top = highlightRect.top - tooltipRect.height - 10;
  let left = highlightRect.left;

  // Check if tooltip would overflow top
  if (top < 10) {
    // Position below the highlight element
    top = highlightRect.bottom + 10;
  }

  // Check if tooltip would overflow right
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  // Check if tooltip would overflow left
  if (left < 10) {
    left = 10;
  }

  // Check if tooltip would overflow bottom
  if (top + tooltipRect.height > viewportHeight - 10) {
    // Try to position above instead
    top = highlightRect.top - tooltipRect.height - 10;
    if (top < 10) {
      // If still overflowing, position at the top of viewport
      top = 10;
    }
  }

  // Ensure tooltip doesn't go off-screen horizontally
  if (left < 10) left = 10;
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  // Ensure tooltip doesn't go off-screen vertically
  if (top < 10) top = 10;
  if (top + tooltipRect.height > viewportHeight - 10) {
    top = viewportHeight - tooltipRect.height - 10;
  }

  tooltip.style.top = `${top + window.scrollY}px`;
  tooltip.style.left = `${left + window.scrollX}px`;

  // Add arrow pointing to the highlight element
  addTooltipArrow(tooltip, highlightRect, top, left, tooltipRect);
}

function addTooltipArrow(
  tooltip,
  highlightRect,
  tooltipTop,
  tooltipLeft,
  tooltipRect
) {
  // Remove existing arrow
  const existingArrow = tooltip.querySelector('.live-debugger-tooltip-arrow');
  if (existingArrow) {
    existingArrow.remove();
  }

  const arrow = document.createElement('div');
  arrow.className = 'live-debugger-tooltip-arrow';

  // Determine arrow position based on tooltip placement
  const tooltipBottom = tooltipTop + tooltipRect.height;
  const highlightTop = highlightRect.top;
  const highlightBottom = highlightRect.bottom;

  if (tooltipBottom < highlightTop) {
    // Tooltip is above highlight - arrow points down
    arrow.classList.add('live-debugger-tooltip-arrow-down');
  } else {
    // Tooltip is below highlight - arrow points up
    arrow.classList.add('live-debugger-tooltip-arrow-up');
  }

  tooltip.appendChild(arrow);
}

function removeTooltip() {
  const existingTooltip = document.getElementById(tooltipID);
  if (existingTooltip) {
    existingTooltip.remove();
  }
}

function showTooltip(data) {
  const highlightElement = document.getElementById(
    'live-debugger-highlight-element'
  );
  if (!highlightElement) {
    // If highlight element doesn't exist yet, try again after a short delay
    setTimeout(() => showTooltip(data), 100);
    return;
  }

  const tooltip = createTooltip(data);
  positionTooltip(tooltip, highlightElement);
}

function handleTooltipResize() {
  const tooltip = document.getElementById(tooltipID);
  const highlightElement = document.getElementById(
    'live-debugger-highlight-element'
  );

  if (tooltip && highlightElement) {
    positionTooltip(tooltip, highlightElement);
  }
}

export default function initTooltip() {
  window.addEventListener('resize', handleTooltipResize);
  window.addEventListener('scroll', handleTooltipResize);

  document.addEventListener('lvdbg:show-tooltip', (event) => {
    showTooltip(event.detail);
  });

  document.addEventListener('lvdbg:remove-tooltip', () => {
    removeTooltip();
  });
}
