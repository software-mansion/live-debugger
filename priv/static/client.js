const highlightElementID = "live-debugger-highlight-element";

window.addEventListener("phx:highlight", (msg) => {
  const highlightElement = document.getElementById(highlightElementID);
  const activeElement = document.querySelector(
    `[${msg.detail.attr}="${msg.detail.val}"]`
  );

  if (highlightElement) {
    highlightElement.remove();
    if (highlightElement.dataset.val === msg.detail.val) {
      return;
    }
  }

  if (isElementVisible(activeElement)) {
    const rect = activeElement.getBoundingClientRect();
    const highlight = document.createElement("div");
    highlight.id = highlightElementID;
    highlight.dataset.attr = msg.detail.attr;
    highlight.dataset.val = msg.detail.val;

    highlight.style.position = "absolute";
    highlight.style.top = `${rect.top + window.scrollY}px`;
    highlight.style.left = `${rect.left + window.scrollX}px`;
    highlight.style.width = `${activeElement.offsetWidth}px`;
    highlight.style.height = `${activeElement.offsetHeight}px`;
    highlight.style.backgroundColor = "rgba(255, 255, 0, 0.2)";
    highlight.style.zIndex = "10000";
    highlight.style.pointerEvents = "none";

    console.log(highlight);
    document.body.appendChild(highlight);
  }
});

window.addEventListener("resize", () => {
  const highlight = document.getElementById(highlightElementID);
  if (highlight) {
    const activeElement = document.querySelector(
      `[${highlight.dataset.attr}="${highlight.dataset.val}"]`
    );
    const rect = activeElement.getBoundingClientRect();

    highlight.style.top = `${rect.top + window.scrollY}px`;
    highlight.style.left = `${rect.left + window.scrollX}px`;
    highlight.style.width = `${activeElement.offsetWidth}px`;
    highlight.style.height = `${activeElement.offsetHeight}px`;
  }
});

function isElementVisible(element) {
  if (!element) return false;

  const style = window.getComputedStyle(element);
  return (
    style.display !== "none" &&
    style.visibility !== "hidden" &&
    style.opacity !== "0"
  );
}

console.log("LiveView JS initialized");
