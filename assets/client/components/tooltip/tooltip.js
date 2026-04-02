import { createTooltip } from './tooltip_creator';
import { positionTooltip } from './tooltip_positioner';
import { addTooltipArrow } from './tooltip_arrow';

const tooltipID = 'live-debugger-tooltip';
const highlightElementID = 'live-debugger-highlight-element';

function getHighlightElement(shadowRoot) {
  return shadowRoot.querySelector(`#${highlightElementID}`);
}

function removeTooltip(shadowRoot) {
  const existingTooltip = shadowRoot.querySelector(`#${tooltipID}`);
  if (existingTooltip) {
    existingTooltip.remove();
  }
}

function showTooltip(data, shadowRoot) {
  const highlightElement = getHighlightElement(shadowRoot);
  if (!highlightElement) {
    return;
  }

  removeTooltip(shadowRoot);
  const tooltip = createTooltip(data, shadowRoot);
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

function handleTooltipResize(shadowRoot) {
  const tooltip = shadowRoot.querySelector(`#${tooltipID}`);
  const highlightElement = getHighlightElement(shadowRoot);

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

function handleShowTooltipEvent(event, shadowRoot) {
  showTooltip(event.detail, shadowRoot);
}

function handleRemoveTooltipEvent(shadowRoot) {
  removeTooltip(shadowRoot);
}

function setupEventListeners(shadowRoot) {
  window.addEventListener('resize', () => handleTooltipResize(shadowRoot));
  window.addEventListener('scroll', () => handleTooltipResize(shadowRoot));

  document.addEventListener('lvdbg:show-tooltip', (event) =>
    handleShowTooltipEvent(event, shadowRoot)
  );
  document.addEventListener('lvdbg:remove-tooltip', () =>
    handleRemoveTooltipEvent(shadowRoot)
  );
}

export default function initTooltip(shadowRoot) {
  setupEventListeners(shadowRoot);
}
