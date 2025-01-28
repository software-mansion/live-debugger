let base_url = null;

function set_base_url(url) {
  base_url = url;
}

function set_iframe_url(url) {
  const iframe = document.getElementById("content");
  iframe.src = url;
}

chrome.runtime.onMessage.addListener(function (message, sender, sendResponse) {
  const componentId = message.componentId;
  const iframe = document.getElementById("content");

  if (componentId) {
    iframe.src = `${base_url}/${componentId}`;
  } else {
    iframe.src = base_url;
  }
});
