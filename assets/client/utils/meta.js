export function getMetaTag() {
  return document.querySelector('meta[name="live-debugger-config"]');
}

export function fetchLiveDebuggerBaseURL(metaTag) {
  return metaTag.getAttribute('url');
}

export function isDebugButtonEnabled(metaTag) {
  return metaTag.hasAttribute('debug-button');
}
