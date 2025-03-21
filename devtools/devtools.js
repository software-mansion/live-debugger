let lvd_url = null;

chrome.devtools.inspectedWindow.eval(
  "`${getLiveDebuggerURL()}/transport_pid/${getSessionId()}`",
  function (result, isException) {
    if (result) {
      lvd_url = result;
    }
  }
);

chrome.devtools.panels.create(
  "LiveDebugger",
  "images/icon-16.png",
  "panel.html",
  function (panel) {
    panel.onShown.addListener(function (window) {
      window.set_iframe_url(lvd_url);
    });
  }
);
