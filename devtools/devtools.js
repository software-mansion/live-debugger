let lvd_url = null;

chrome.devtools.inspectedWindow.eval(
  "getLiveDebuggerURL()",
  function (result, isException) {
    if (isException) {
      console.log(
        "Couldn't find url. Ensure you've turned on browser features in the config and added LiveDebugger scripts to your application root layout."
      );
    } else {
      lvd_url = result;
    }
  }
);

chrome.devtools.panels.create(
  "LiveViewDebugger",
  "images/icon-16.png",
  "panel.html",
  function (panel) {
    panel.onShown.addListener(function (window) {
      window.set_iframe_url(lvd_url);
    });
  }
);
