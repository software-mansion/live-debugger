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
          window.set_iframe_url(await getLiveDebuggerSessionURL(browser));
        } catch (error) {
          window.set_iframe_url(null);
        }
      }
    });

    browser.webNavigation.onCompleted.addListener(async () => {
      try {
        panelWindow.set_iframe_url(await getLiveDebuggerSessionURL(browser));
      } catch (error) {
        panelWindow.set_iframe_url(null);
      }
    });
  },
);
