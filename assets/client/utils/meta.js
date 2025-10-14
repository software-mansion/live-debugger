export function fetchDebuggedSocketIDs() {
  return new Promise((resolve) => {
    const liveViewElements = document.querySelectorAll('[data-phx-session]');
    const rootIDs = {};
    const mainID = document.querySelector('[data-phx-main]')?.id;

    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        console.log('mutation');

        if (
          mutation.type === 'attributes' &&
          mutation.attributeName === 'data-phx-root-id'
        ) {
          rootIDs[mutation.target.id] =
            mutation.target.getAttribute('data-phx-root-id');

          if (Object.keys(rootIDs).length >= liveViewElements.length) {
            const rootSocketIDs = new Set(Object.values(rootIDs));
            rootSocketIDs.delete(mainID);

            observer.disconnect();

            resolve({
              mainSocketID: mainID,
              rootSocketIDs: [...rootSocketIDs],
            });
          }
        }
      });
    });

    liveViewElements.forEach((el) => {
      observer.observe(el, { attributes: true });
    });
  });
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
