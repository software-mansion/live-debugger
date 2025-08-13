import tooltipHtml from './tooltip.html';
import { createElement } from '../../utils/dom';

const tooltipID = 'live-debugger-tooltip';

function populateTypeInfo(tooltip, data) {
  const typeInfo = tooltip.querySelector('.type-info');
  const typeText = typeInfo.querySelector('.type-text');
  const typeSquare = typeInfo.querySelector('.live-debugger-type-square');

  typeText.textContent = data.type;
  typeSquare.style.backgroundColor =
    data.type === 'LiveComponent' ? '#87CCE8' : '#b1dfd0';
}

function populateIdInfo(tooltip, data) {
  const idInfo = tooltip.querySelector('.id-info');
  const label = idInfo.querySelector('.label');
  const value = idInfo.querySelector('.value');

  label.textContent = `${data.id_key}:`;
  value.textContent = data.id_value;
}

function populateInfoSection(tooltip, data) {
  populateTypeInfo(tooltip, data);
  populateIdInfo(tooltip, data);
}

function setModuleName(tooltip, data) {
  const moduleName = tooltip.querySelector('.live-debugger-tooltip-module');
  moduleName.textContent = data.module || 'Element';
}

function createTooltip(data) {
  const tooltip = createElement(tooltipHtml);

  setModuleName(tooltip, data);
  populateInfoSection(tooltip, data);

  document.body.appendChild(tooltip);
  return tooltip;
}

function calculateInitialPosition(highlightRect, tooltipRect) {
  let top = highlightRect.top - tooltipRect.height - 10;
  let left = highlightRect.left;

  return { top, left };
}

function adjustVerticalPosition(
  top,
  highlightRect,
  tooltipRect,
  viewportHeight
) {
  // Check if tooltip would overflow top
  if (top < 10) {
    // Position below the highlight element
    top = highlightRect.bottom + 10;
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

  // Ensure tooltip doesn't go off-screen vertically
  if (top < 10) top = 10;
  if (top + tooltipRect.height > viewportHeight - 10) {
    top = viewportHeight - tooltipRect.height - 10;
  }

  return top;
}

function adjustHorizontalPosition(left, tooltipRect, viewportWidth) {
  // Check if tooltip would overflow right
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  // Check if tooltip would overflow left
  if (left < 10) {
    left = 10;
  }

  // Ensure tooltip doesn't go off-screen horizontally
  if (left < 10) left = 10;
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  return left;
}

function applyPosition(tooltip, top, left) {
  tooltip.style.top = `${top + window.scrollY}px`;
  tooltip.style.left = `${left + window.scrollX}px`;
}

function positionTooltip(tooltip, highlightElement) {
  if (!highlightElement || !tooltip) return;

  const highlightRect = highlightElement.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  let { top, left } = calculateInitialPosition(highlightRect, tooltipRect);

  top = adjustVerticalPosition(top, highlightRect, tooltipRect, viewportHeight);
  left = adjustHorizontalPosition(left, tooltipRect, viewportWidth);

  applyPosition(tooltip, top, left);

  addTooltipArrow(tooltip, highlightRect, top, left, tooltipRect);
}

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

function addTooltipArrow(
  tooltip,
  highlightRect,
  tooltipTop,
  tooltipLeft,
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

function removeTooltip() {
  const existingTooltip = document.getElementById(tooltipID);
  if (existingTooltip) {
    existingTooltip.remove();
  }
}

function getHighlightElement() {
  return document.getElementById('live-debugger-highlight-element');
}

function showTooltip(data) {
  const highlightElement = getHighlightElement();
  if (!highlightElement) {
    return;
  }

  const tooltip = createTooltip(data);
  positionTooltip(tooltip, highlightElement);
}

function handleTooltipResize() {
  const tooltip = document.getElementById(tooltipID);
  const highlightElement = getHighlightElement();

  if (tooltip && highlightElement) {
    positionTooltip(tooltip, highlightElement);
  }
}

function handleShowTooltipEvent(event) {
  showTooltip(event.detail);
}

function handleRemoveTooltipEvent() {
  removeTooltip();
}

function setupEventListeners() {
  window.addEventListener('resize', handleTooltipResize);
  window.addEventListener('scroll', handleTooltipResize);

  document.addEventListener('lvdbg:show-tooltip', handleShowTooltipEvent);
  document.addEventListener('lvdbg:remove-tooltip', handleRemoveTooltipEvent);
}

export default function initTooltip() {
  setupEventListeners();
}
