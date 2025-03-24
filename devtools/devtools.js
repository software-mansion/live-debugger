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

    panel.onShown.addListener(async (window) => {
      panelWindow = window;
      window.set_iframe_url(await getLiveDebuggerSessionURL());
    });

    chrome.webNavigation.onCompleted.addListener(async () => {
      panelWindow.set_iframe_url(await getLiveDebuggerSessionURL());
    });
  }
);
