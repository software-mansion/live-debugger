export function fetchDebuggedSocketID() {
  let el;
  if ((el = document.querySelector('[data-phx-main]'))) {
    return el.id;
  }
  if ((el = document.querySelector('[id^="phx-"]'))) {
    return el.id;
  }
  if ((el = document.querySelector('[data-phx-root-id]'))) {
    return el.getAttribute('data-phx-root-id');
  }
}

export function getMetaTag() {
  const metaTag = document.querySelector('meta[name="live-debugger-config"]');

  if (metaTag) {
    return metaTag;
  } else {
    const message = `
    LiveDebugger meta tag not found!
    If you have recently bumped LiveDebugger version, please update your layout according to the instructions in the GitHub README.
    You can find it here: https://github.com/software-mansion/live-debugger#installation
    `;

    throw new Error(message);
  }
}

export function fetchLiveDebuggerBaseURL(metaTag) {
  return metaTag.getAttribute('url');
}

export function isDebugButtonEnabled(metaTag) {
  return metaTag.hasAttribute('debug-button');
}

export function isHighlightingEnabled(metaTag) {
  return metaTag.hasAttribute('highlighting');
}
