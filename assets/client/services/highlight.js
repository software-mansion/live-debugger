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

function getHighlightRect(element) {
  if (!element) return null;

  const rect = element.getBoundingClientRect();
  if (rect.width !== 0 || rect.height !== 0) return rect;

  const childRects = [...element.children]
    .map((child) => getHighlightRect(child))
    .filter(Boolean);

  if (childRects.length === 0) return null;

  const top = Math.min(...childRects.map((r) => r.top));
  const left = Math.min(...childRects.map((r) => r.left));
  const right = Math.max(...childRects.map((r) => r.right));
  const bottom = Math.max(...childRects.map((r) => r.bottom));

  return {
    top,
    left,
    right,
    bottom,
    width: right - left,
    height: bottom - top,
  };
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

  if (!activeElement) return;

  const rect = getHighlightRect(activeElement);

  if (!rect) return;

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

  if (!activeElement) return;

  const rect = getHighlightRect(activeElement);

  if (!rect) return;

  highlight.style.top = `${rect.top + window.scrollY}px`;
  highlight.style.left = `${rect.left + window.scrollX}px`;
  highlight.style.width = `${rect.width}px`;
  highlight.style.height = `${rect.height}px`;
}

function handlePulse({ detail }, shadowRoot) {
  const activeElement = document.querySelector(
    `[${detail.attr}="${detail.val}"]`
  );

  if (!activeElement) return;

  const rect = getHighlightRect(activeElement);

  if (!rect) return;

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
