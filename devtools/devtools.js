function getLiveDebuggerSessionURL() {
  return new Promise((resolve, reject) => {
    chrome.devtools.inspectedWindow.eval(
      "`${getLiveDebuggerURL()}/transport_pid/${getSessionId()}`",
      (result, isException) => {
        if (isException) {
          reject(isException);
        } else {
          resolve(result);
        }
      }
    );
  });
}

chrome.devtools.panels.create(
  "LiveDebugger",
  "images/icon-16.png",
  "panel.html",
  function (panel) {
    let panelWindow;
    let isShown = false;

    panel.onShown.addListener(async (window) => {
      if (!isShown) {
        panelWindow = window;
        isShown = true;
        try {
          window.set_iframe_url(await getLiveDebuggerSessionURL());
        } catch (error) {
          window.set_iframe_url(null);
        }
      }
    });

    chrome.webNavigation.onCompleted.addListener(async () => {
      try {
        panelWindow.set_iframe_url(await getLiveDebuggerSessionURL());
      } catch (error) {
        panelWindow.set_iframe_url(null);
      }
    });
  }
);
