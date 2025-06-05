const liveDebuggerPanelsPorts = [];

browser.webNavigation.onCompleted.addListener(async (details) => {
  liveDebuggerPanelsPorts.forEach((port) => {
    try {
      port.postMessage({
        type: "navigationCompleted",
        details: details,
      });
    } catch (error) {
      console.error("Error sending message to port:", error);
    }
  });
});

browser.runtime.onConnect.addListener((port) => {
  liveDebuggerPanelsPorts.push(port);

  port.onDisconnect.addListener(() => {
    const index = liveDebuggerPanelsPorts.indexOf(port);
    if (index !== -1) {
      liveDebuggerPanelsPorts.splice(index, 1);
    }
  });
});
