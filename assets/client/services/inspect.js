export default function initElementInspection({ socketID, sessionURL }) {
  let inspectMode = false;
  let lastID = null;

  const handleMove = (event) => {
    const cid = event.target.closest('[data-phx-component]')?.dataset
      .phxComponent;

    const detail = getHighlightDetail(cid, socketID);

    if (detail.val === lastID) {
      return;
    }

    lastID = detail.val;

    pushHighlightEvent(detail);
  };

  const handleInspect = (event) => {
    event.stopPropagation();

    const cid = event.target.closest('[data-phx-component]')?.dataset
      .phxComponent;

    const detail = getHighlightDetail(cid, socketID);

    pushPulseEvent(detail);

    window.open(sessionURL + (cid ? `?node_id=${detail.val}` : ''), '_blank');

    disableInspectMode();
  };

  const handleRightClick = (event) => {
    event.preventDefault();
    disableInspectMode();
  };

  const handleEscape = (event) => {
    if (event.key === 'Escape') {
      disableInspectMode();
    }
  };

  const disableInspectMode = () => {
    if (!inspectMode) {
      return;
    }

    inspectMode = false;
    lastID = null;

    document
      .getElementById('live-debugger-debug-button')
      .classList.remove('live-debugger-inspect-mode');

    pushClearEvent();

    document.body.classList.remove('force-cursor-crosshair');
    document.body.removeEventListener('click', handleInspect);
    document.body.removeEventListener('mouseover', handleMove);
    document.removeEventListener('contextmenu', handleRightClick);
    document.removeEventListener('keydown', handleEscape);
  };

  const enableInspectMode = () => {
    if (inspectMode) {
      return;
    }

    inspectMode = true;

    document
      .getElementById('live-debugger-debug-button')
      .classList.add('live-debugger-inspect-mode');

    document.body.classList.add('force-cursor-crosshair');
    document.body.addEventListener('click', handleInspect);
    document.body.addEventListener('mouseover', handleMove);
    document.addEventListener('contextmenu', handleRightClick);
    document.addEventListener('keydown', handleEscape);
  };

  document.addEventListener('lvdbg:inspect-button-click', (event) => {
    setTimeout(enableInspectMode);
  });
}

function pushHighlightEvent(detail) {
  const highlightEvent = new CustomEvent('lvdbg:inspect-highlight', {
    detail,
  });

  document.dispatchEvent(highlightEvent);
}

function pushPulseEvent(detail) {
  const pulseEvent = new CustomEvent('lvdbg:inspect-pulse', {
    detail,
  });

  document.dispatchEvent(pulseEvent);
}

function getHighlightDetail(cid, socketID) {
  if (!cid) {
    return {
      attr: 'id',
      val: socketID,
    };
  }

  return {
    attr: 'data-phx-component',
    val: cid,
  };
}

function pushClearEvent() {
  const clearEvent = new CustomEvent('lvdbg:inspect-clear');

  document.dispatchEvent(clearEvent);
}
