import { createTooltip } from './tooltip_creator';
import { positionTooltip } from './tooltip_positioner';
import { addTooltipArrow } from './tooltip_arrow';

const tooltipID = 'live-debugger-tooltip';
const highlightElementID = 'live-debugger-highlight-element';

function getHighlightElement() {
  return document.getElementById(highlightElementID);
}

function removeTooltip() {
  const existingTooltip = document.getElementById(tooltipID);
  if (existingTooltip) {
    existingTooltip.remove();
  }
}

function showTooltip(data) {
  const highlightElement = getHighlightElement();
  if (!highlightElement) {
    return;
  }

  removeTooltip();
  const tooltip = createTooltip(data);
  const positionData = positionTooltip(tooltip, highlightElement);

  if (positionData) {
    addTooltipArrow(
      tooltip,
      highlightElement.getBoundingClientRect(),
      positionData.top,
      positionData.tooltipRect
    );
  }
}

function handleTooltipResize() {
  const tooltip = document.getElementById(tooltipID);
  const highlightElement = getHighlightElement();

  if (tooltip && highlightElement) {
    const positionData = positionTooltip(tooltip, highlightElement);

    if (positionData) {
      addTooltipArrow(
        tooltip,
        highlightElement.getBoundingClientRect(),
        positionData.top,
        positionData.tooltipRect
      );
    }
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
