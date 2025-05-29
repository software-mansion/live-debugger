browser.devtools.panels.create(
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
          window.setIframeUrl(await getLiveDebuggerSessionURL(browser));
        } catch (error) {
          window.setIframeUrl(null);
        }
      }
    });

    browser.webNavigation.onCompleted.addListener(async (details) => {
      if (
        details.tabId === chrome.devtools.inspectedWindow.tabId &&
        allowRedirects(browser)
      ) {
        try {
          panelWindow.setIframeUrl(await getLiveDebuggerSessionURL(browser));
        } catch (error) {
          panelWindow.setIframeUrl(null);
        }
      }
    });
  }
);
