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
          window.set_iframe_url(await getLiveDebuggerSessionURL(chrome));
        } catch (error) {
          window.set_iframe_url(null);
        }
      }
    });

    chrome.webNavigation.onCompleted.addListener(async (details) => {
      if (details.tabId === chrome.devtools.inspectedWindow.tabId) {
        try {
          panelWindow.set_iframe_url(await getLiveDebuggerSessionURL(chrome));
        } catch (error) {
          panelWindow.set_iframe_url(null);
        }
      }
    });
  },
);
