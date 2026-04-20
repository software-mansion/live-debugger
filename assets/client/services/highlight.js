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
const streamItemColors = ['#8bca8480'];

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

function getHighlightRect(element) {
  if (!element) return null;

  const rects = [element, ...element.children]
    .map((el) => el.getBoundingClientRect())
    .filter((r) => r.width !== 0 || r.height !== 0);

  if (rects.length === 0) return null;

  const top = Math.min(...rects.map((r) => r.top));
  const left = Math.min(...rects.map((r) => r.left));
  const right = Math.max(...rects.map((r) => r.right));
  const bottom = Math.max(...rects.map((r) => r.bottom));

  return { top, left, width: right - left, height: bottom - top };
}

function getHighlightColors(type) {
  switch (type) {
    case 'LiveComponent':
      return liveComponentsColors;
    case 'LiveView':
      return liveViewColors;
    case 'StreamItem':
      return streamItemColors;
    default:
      return liveViewColors;
  }
}

function createHighlightElement(rect, detail, id) {
  const highlight = document.createElement('div');

  highlight.id = id;
  highlight.dataset.attr = detail.attr;
  highlight.dataset.val = detail.val;

  highlight.style.position = 'absolute';
  highlight.style.top = `${rect.top + window.scrollY}px`;
  highlight.style.left = `${rect.left + window.scrollX}px`;
  highlight.style.width = `${rect.width}px`;
  highlight.style.height = `${rect.height}px`;
  highlight.style.backgroundColor = getHighlightColors(detail.type)[0];
  highlight.style.zIndex = '10000';
  highlight.style.pointerEvents = 'none';

  return highlight;
}

function removeHighlightElement(shadowRoot) {
  shadowRoot.querySelector(`#${highlightElementID}`)?.remove();
  dispatchCustomEvent('lvdbg:remove-tooltip');
}

function handleHighlight({ detail }, shadowRoot) {
  let highlightElement = shadowRoot.querySelector(`#${highlightElementID}`);

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

  if (!isElementVisible(activeElement)) return;

  const rect = getHighlightRect(activeElement);

  highlightElement = createHighlightElement(rect, detail, highlightElementID);

  shadowRoot.appendChild(highlightElement);
  showTooltip(detail);
}

function handleHighlightResize(shadowRoot) {
  const highlight = shadowRoot.querySelector(`#${highlightElementID}`);
  if (!highlight) return;

  const activeElement = document.querySelector(
    `[${highlight.dataset.attr}="${highlight.dataset.val}"]`
  );

  if (!isElementVisible(activeElement)) return;

  const rect = getHighlightRect(activeElement);

  highlight.style.top = `${rect.top + window.scrollY}px`;
  highlight.style.left = `${rect.left + window.scrollX}px`;
  highlight.style.width = `${rect.width}px`;
  highlight.style.height = `${rect.height}px`;
}

function handlePulse({ detail }, shadowRoot) {
  const activeElement = document.querySelector(
    `[${detail.attr}="${detail.val}"]`
  );

  if (!isElementVisible(activeElement)) return null;

  const rect = getHighlightRect(activeElement);

  const highlightPulse = createHighlightElement(
    rect,
    detail,
    highlightPulseElementID
  );
  shadowRoot.appendChild(highlightPulse);

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
    { duration: 500, iterations: 1, delay: 200 }
  ).onfinish = () => highlightPulse.remove();
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

export default function initHighlight(debugChannel, shadowRoot) {
  document.addEventListener('lvdbg:inspect-highlight', (event) =>
    handleHighlight(event, shadowRoot)
  );
  document.addEventListener('lvdbg:inspect-pulse', (event) =>
    handlePulse(event, shadowRoot)
  );
  document.addEventListener('lvdbg:inspect-clear', () =>
    removeHighlightElement(shadowRoot)
  );

  debugChannel.on('highlight', (e) =>
    handleHighlight({ detail: e }, shadowRoot)
  );
  debugChannel.on('pulse', (e) => handlePulse({ detail: e }, shadowRoot));

  window.addEventListener('resize', () => handleHighlightResize(shadowRoot));
}
