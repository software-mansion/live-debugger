import { dispatchCustomEvent } from '../utils/dom';

const highlightElementID = 'live-debugger-highlight-element';
const highlightPulseElementID = 'live-debugger-highlight-pulse-element';
const liveViewColors = ['#ffe78080', '#ffe78060', '#ffe78030', '#ffe78000'];
const liveComponentsColors = [
  '#87CCE880',
  '#87CCE860',
  '#87CCE830',
  '#87CCE800',
];

const isElementVisible = (element) => {
  if (!element) return false;

  if (element.checkVisibility) {
    return element.checkVisibility();
  }

  const style = window.getComputedStyle(element);
  return (
    style.display !== 'none' &&
    style.visibility !== 'hidden' &&
    style.opacity !== '0'
  );
};

function getHighlightColors(type) {
  return type === 'LiveComponent' ? liveComponentsColors : liveViewColors;
}

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
  highlight.style.backgroundColor = getHighlightColors(detail.type)[0];
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

    const colors = getHighlightColors(detail.type);

    highlightPulse.animate(
      [
        {
          width: `${w}px`,
          height: `${h}px`,
          transform: 'translate(0, 0)',
          backgroundColor: colors[1],
        },
        {
          width: `${w + 20}px`,
          height: `${h + 20}px`,
          transform: 'translate(-10px, -10px)',
          backgroundColor: colors[2],
        },
        {
          width: `${w + 40}px`,
          height: `${h + 40}px`,
          transform: 'translate(-20px, -20px)',
          backgroundColor: colors[3],
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
  const requiredKeys = ['module', 'type', 'id_key', 'id_value'];
  const hasAllKeys = requiredKeys.every((key) => detail.hasOwnProperty(key));

  if (!hasAllKeys) {
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

export default function initHighlight(debugChannel) {
  document.addEventListener('lvdbg:inspect-highlight', handleHighlight);
  document.addEventListener('lvdbg:inspect-pulse', handlePulse);
  document.addEventListener('lvdbg:inspect-clear', removeHighlightElement);

  debugChannel.on('highlight', (e) => handleHighlight({ detail: e }));
  debugChannel.on('pulse', (e) => handlePulse({ detail: e }));

  window.addEventListener('resize', handleHighlightResize);
}
