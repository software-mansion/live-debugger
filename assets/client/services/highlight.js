import { dispatchCustomEvent } from '../utils/dom';

const highlightElementID = 'live-debugger-highlight-element';
const highlightPulseElementID = 'live-debugger-highlight-pulse-element';

const isElementVisible = (element) => {
  if (!element) return false;

  const style = window.getComputedStyle(element);
  return (
    style.display !== 'none' &&
    style.visibility !== 'hidden' &&
    style.opacity !== '0'
  );
};

function createHighlightElement(activeElement, detail, id) {
  const rect = activeElement.getBoundingClientRect();
  const highlight = document.createElement('div');

  highlight.id = id;
  highlight.dataset.attr = detail.attr;
  highlight.dataset.val = detail.val;

  highlight.style.position = 'absolute';
  highlight.style.top = `${rect.top + window.scrollY}px`;
  highlight.style.left = `${rect.left + window.scrollX}px`;
  highlight.style.width = `${activeElement.offsetWidth}px`;
  highlight.style.height = `${activeElement.offsetHeight}px`;
  highlight.style.backgroundColor = '#87CCE880';
  highlight.style.zIndex = '10000';
  highlight.style.pointerEvents = 'none';

  return highlight;
}

function removeHighlightElement() {
  const highlightElement = document.getElementById(highlightElementID);

  if (highlightElement) {
    highlightElement.remove();
  }

  dispatchCustomEvent('lvdbg:remove-tooltip');
}

function handleHighlight({ detail }) {
  let highlightElement = document.getElementById(highlightElementID);

  if (highlightElement) {
    highlightElement.remove();
    dispatchCustomEvent('lvdbg:remove-tooltip');

    const toClear = detail.attr === undefined || detail.val === undefined;
    const sameElement = highlightElement.dataset.val === detail.val;

    if (toClear || sameElement) {
      return;
    }
  }

  const activeElement = document.querySelector(
    `[${detail.attr}="${detail.val}"]`
  );

  if (isElementVisible(activeElement)) {
    highlightElement = createHighlightElement(
      activeElement,
      detail,
      highlightElementID
    );

    if (detail.type === 'LiveView') {
      highlightElement.style.backgroundColor = '#00BB0080';
    }

    document.body.appendChild(highlightElement);
    showTooltip(detail);
  }
}

function handleHighlightResize() {
  const highlight = document.getElementById(highlightElementID);
  if (highlight) {
    const activeElement = document.querySelector(
      `[${highlight.dataset.attr}="${highlight.dataset.val}"]`
    );
    const rect = activeElement.getBoundingClientRect();

    highlight.style.top = `${rect.top + window.scrollY}px`;
    highlight.style.left = `${rect.left + window.scrollX}px`;
    highlight.style.width = `${activeElement.offsetWidth}px`;
    highlight.style.height = `${activeElement.offsetHeight}px`;
  }
}

function handlePulse({ detail }) {
  const activeElement = document.querySelector(
    `[${detail.attr}="${detail.val}"]`
  );

  if (isElementVisible(activeElement)) {
    const highlightPulse = createHighlightElement(
      activeElement,
      detail,
      highlightPulseElementID
    );

    document.body.appendChild(highlightPulse);

    const w = highlightPulse.offsetWidth;
    const h = highlightPulse.offsetHeight;

    highlightPulse.animate(
      [
        {
          width: `${w}px`,
          height: `${h}px`,
          transform: 'translate(0, 0)',
          backgroundColor: '#87CCE860',
        },
        {
          width: `${w + 20}px`,
          height: `${h + 20}px`,
          transform: 'translate(-10px, -10px)',
          backgroundColor: '#87CCE830',
        },
        {
          width: `${w + 40}px`,
          height: `${h + 40}px`,
          transform: 'translate(-20px, -20px)',
          backgroundColor: '#87CCE800',
        },
      ],
      {
        duration: 500,
        iterations: 1,
        delay: 200,
      }
    ).onfinish = () => {
      highlightPulse.remove();
    };
  }
}

function showTooltip(detail) {
  // Check if detail object has all required keys
  const requiredKeys = ['module', 'type', 'id_key', 'id_value'];
  const hasAllKeys = requiredKeys.every((key) => detail.hasOwnProperty(key));

  if (!hasAllKeys) {
    console.warn(
      'Detail object missing required keys:',
      requiredKeys.filter((key) => !detail.hasOwnProperty(key))
    );
    return;
  }

  const props = {
    detail: {
      module: detail.module,
      type: detail.type,
      id_key: detail.id_key,
      id_value: detail.id_value,
    },
  };

  dispatchCustomEvent('lvdbg:show-tooltip', props);
}

export default function initHighlight() {
  document.addEventListener('lvdbg:inspect-highlight', handleHighlight);
  document.addEventListener('lvdbg:inspect-pulse', handlePulse);
  document.addEventListener('lvdbg:inspect-clear', removeHighlightElement);

  window.addEventListener('phx:highlight', handleHighlight);
  window.addEventListener('resize', handleHighlightResize);
  window.addEventListener('phx:pulse', handlePulse);
}
