let lvd_url = null;

chrome.devtools.inspectedWindow.eval(
  'document.querySelector("#live-debugger-button").href',
  function (result, isException) {
    if (isException) {
      console.log(
        "Couldn't find url. Ensure you've added LiveDebugger.debug_button/1 to your layout."
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
      window.set_base_url(lvd_url);
    });
  }
);
