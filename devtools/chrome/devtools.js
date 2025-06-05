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
          window.setIframeUrl(await getLiveDebuggerSessionURL(chrome));
        } catch (error) {
          window.setIframeUrl(null);
        }
      }
    });

    chrome.webNavigation.onCompleted.addListener(async (details) => {
      if (
        details.tabId === chrome.devtools.inspectedWindow.tabId &&
        (await allowRedirects(chrome))
      ) {
        try {
          panelWindow.setIframeUrl(await getLiveDebuggerSessionURL(chrome));
        } catch (error) {
          panelWindow.setIframeUrl(null);
        }
      }
    });
  },
);
