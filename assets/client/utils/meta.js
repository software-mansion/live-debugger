export function fetchDebuggedSocketIDs() {
  return new Promise((resolve) => {
    const liveViewElements = document.querySelectorAll('[data-phx-session]');
    const rootIDsMapping = {};
    const mainID = document.querySelector('[data-phx-main]')?.id;

    const handleMutation = (mutation) => {
      if (!isRootIDAttributeChanged(mutation)) return;

      registerRootID(rootIDsMapping, mutation.target);

      if (isAllRootIDsRegistered(rootIDsMapping, liveViewElements)) {
        observer.disconnect();

        resolve({
          mainSocketID: mainID,
          rootSocketIDs: getRootSocketIDs(rootIDsMapping, mainID),
        });
      }
    };

    const observer = new MutationObserver((mutations) => {
      mutations.forEach(handleMutation);
    });

    liveViewElements.forEach((el) => {
      observer.observe(el, { attributes: true });
    });
  });
}

function isRootIDAttributeChanged(mutation) {
  return (
    mutation.type === 'attributes' &&
    mutation.attributeName === 'data-phx-root-id'
  );
}

function registerRootID(rootIDs, target) {
  rootIDs[target.id] = target.getAttribute('data-phx-root-id');
}

function isAllRootIDsRegistered(rootIDs, liveViewElements) {
  return Object.keys(rootIDs).length >= liveViewElements.length;
}

function getRootSocketIDs(rootIDs, mainID) {
  const rootSocketIDs = new Set(Object.values(rootIDs));
  rootSocketIDs.delete(mainID);
  return [...rootSocketIDs];
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
