// This file is being run in the client's debugged application
// It introduces browser features that are not mandatory for LiveDebugger to run

// Fetch LiveDebugger URL
const URL = document
  .getElementById('live-debugger-scripts')
  .src.replace('/assets/client.js', '');

// Debug button
document.addEventListener('DOMContentLoaded', function () {
  const session_id = document.querySelector('[data-phx-main]').id;
  const debugButtonHtml = /*html*/ `
      <div id="debug-button" style="
        position: fixed;
        height: 40px;
        width: 40px;
        padding-left: 5px;
        padding-right: 5px;
        border-radius: 10px;
        background-color: #4C2B8A;
        display: flex;
        gap: 5px;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        bottom: 20px;
        right: 20px;
        cursor: grab;">
        <a href="${URL}/${session_id}" target="_blank">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-bug"><path d="m8 2 1.88 1.88"/><path d="M14.12 3.88 16 2"/><path d="M9 7.13v-1a3.003 3.003 0 1 1 6 0v1"/><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6"/><path d="M12 20v-9"/><path d="M6.53 9C4.6 8.8 3 7.1 3 5"/><path d="M6 13H2"/><path d="M3 21c0-2.1 1.7-3.9 3.8-4"/><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4"/><path d="M22 13h-4"/><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4"/></svg>
        </a>
      </div>
  `;

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = debugButtonHtml;
  const debugButton = tempDiv.firstElementChild;
  document.body.appendChild(debugButton);

  let dragging = false;

  const onMouseDown = (event) => {
    if (event.button !== 0 || event.ctrlKey) return;
    event.preventDefault();
    posXStart = event.clientX;
    posYStart = event.clientY;
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
    debugButton.style.cursor = 'grabbing';
    dragging = false;
  };

  const onMouseMove = (event) => {
    if (!event.clientX || !event.clientY) return;
    dragging = true;
    posX = posXStart - event.clientX;
    posY = posYStart - event.clientY;
    posXStart = event.clientX;
    posYStart = event.clientY;
    debugButton.style.top = `${debugButton.offsetTop - posY}px`;
    debugButton.style.left = `${debugButton.offsetLeft - posX}px`;
  };

  const onMouseUp = () => {
    document.removeEventListener('mousemove', onMouseMove);
    document.removeEventListener('mouseup', onMouseUp);
    debugButton.style.cursor = 'grab';

    if (debugButton.offsetTop < 0) {
      debugButton.style.top = debugButton.style.bottom;
    }
    if (debugButton.offsetTop + debugButton.clientHeight > window.innerHeight) {
      debugButton.style.top = '';
    }
    if (debugButton.offsetLeft < 0) {
      debugButton.style.left = debugButton.style.right;
    }
    if (debugButton.offsetLeft + debugButton.clientWidth > window.innerWidth) {
      debugButton.style.left = '';
    }
  };

  const onClick = (event) => {
    if (dragging) {
      event.preventDefault();
      dragging = false;
    }
  };

  window.addEventListener('resize', () => {
    if (
      debugButton.offsetLeft +
        debugButton.clientWidth +
        Number.parseInt(debugButton.style.right) >
      window.innerWidth
    ) {
      debugButton.style.left = '';
    }
    if (
      debugButton.offsetTop +
        debugButton.clientHeight +
        Number.parseInt(debugButton.style.bottom) >
      window.innerHeight
    ) {
      debugButton.style.top = '';
    }
  });

  // Highlighting feature
  function isElementVisible(element) {
    if (!element) return false;

    const style = window.getComputedStyle(element);
    return (
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      style.opacity !== '0'
    );
  }

  const highlightElementID = 'live-debugger-highlight-element';

  window.addEventListener('phx:highlight', (msg) => {
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
      const highlight = document.createElement('div');
      highlight.id = highlightElementID;
      highlight.dataset.attr = msg.detail.attr;
      highlight.dataset.val = msg.detail.val;

      highlight.style.position = 'absolute';
      highlight.style.top = `${rect.top + window.scrollY}px`;
      highlight.style.left = `${rect.left + window.scrollX}px`;
      highlight.style.width = `${activeElement.offsetWidth}px`;
      highlight.style.height = `${activeElement.offsetHeight}px`;
      highlight.style.backgroundColor = 'rgba(255, 255, 0, 0.2)';
      highlight.style.zIndex = '10000';
      highlight.style.pointerEvents = 'none';

      console.log(highlight);
      document.body.appendChild(highlight);
    }
  });

  window.addEventListener('resize', () => {
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

  debugButton.addEventListener('mousedown', onMouseDown);
  debugButton.addEventListener('click', onClick);
});

// Finalize
console.info(`LiveDebugger available at: ${URL}`);
