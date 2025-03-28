function getLiveDebuggerSessionURL() {
  return new Promise((resolve, reject) => {
    chrome.devtools.inspectedWindow.eval(
      "getLiveDebuggerURL()",
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
        window.set_iframe_url(await getLiveDebuggerSessionURL());
        isShown = true;
      }
    });

    chrome.webNavigation.onCompleted.addListener(async () => {
      panelWindow.set_iframe_url(await getLiveDebuggerSessionURL());
    });
  }
);
