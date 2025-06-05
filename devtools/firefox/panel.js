const iframe = document.getElementById("content");
const errorInfo = document.getElementById("error-info");

function setIframeUrl(url) {
  if (url) {
    iframe.src = url;
    iframe.hidden = false;
    errorInfo.hidden = true;
    errorInfo.style.display = "none";
  } else {
    iframe.hidden = true;
    errorInfo.hidden = false;
    errorInfo.style.display = "flex";
  }
}

const port = browser.runtime.connect({ name: "LiveDebuggerConnection" });

port.onMessage.addListener(async (message) => {
  if (message.type !== "navigationCompleted") return;

  if (
    message.details.tabId === browser.devtools.inspectedWindow.tabId &&
    (await allowRedirects(browser))
  ) {
    try {
      setIframeUrl(await getLiveDebuggerSessionURL(browser));
    } catch (error) {
      setIframeUrl(null);
    }
  }
});
