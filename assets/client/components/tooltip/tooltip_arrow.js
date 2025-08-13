function removeExistingArrow(tooltip) {
  const existingArrow = tooltip.querySelector('.live-debugger-tooltip-arrow');
  if (existingArrow) {
    existingArrow.remove();
  }
}

function createArrowElement() {
  const arrow = document.createElement('div');
  arrow.className = 'live-debugger-tooltip-arrow';
  return arrow;
}

function determineArrowDirection(tooltipTop, tooltipRect, highlightRect) {
  const tooltipBottom = tooltipTop + tooltipRect.height;
  const highlightTop = highlightRect.top;

  return tooltipBottom < highlightTop ? 'down' : 'up';
}

export function addTooltipArrow(
  tooltip,
  highlightRect,
  tooltipTop,
  tooltipRect
) {
  removeExistingArrow(tooltip);

  const arrow = createArrowElement();
  const direction = determineArrowDirection(
    tooltipTop,
    tooltipRect,
    highlightRect
  );

  if (direction === 'down') {
    arrow.classList.add('live-debugger-tooltip-arrow-down');
  } else {
    arrow.classList.add('live-debugger-tooltip-arrow-up');
  }

  tooltip.appendChild(arrow);
}
