let lvd_socket_id = null;

chrome.devtools.inspectedWindow.eval(
  "window.liveSocket.main.id",
  function (result, isException) {
    if (isException) {
      console.log("Couldn't find socket id");
    } else {
      lvd_socket_id = result;
    }
  }
);

chrome.devtools.panels.create(
  "LiveViewDebugger",
  "images/icon-16.png",
  "panel.html",
  function (panel) {
    panel.onShown.addListener(function (window) {
      window.set_socket_id(lvd_socket_id);
    });
  }
);
