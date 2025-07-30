export default function initElementInspection({ socketID, sessionURL }) {
  let inspectMode = false;
  let lastID = null;

  const handleMove = (event) => {
    const cid = event.target.closest('[data-phx-component]')?.dataset
      .phxComponent;

    let attr = null;
    let val = null;

    if (!cid) {
      attr = 'id';
      val = socketID;
    } else {
      attr = 'data-phx-component';
      val = cid;
    }

    if (val === lastID) {
      return;
    }

    lastID = val;

    const highlightEvent = new CustomEvent('live-debugger-inspect-highlight', {
      detail: {
        attr,
        val,
      },
    });

    document.dispatchEvent(highlightEvent);
  };

  const handleInspect = (event) => {
    event.stopPropagation();

    const cid = event.target.closest('[data-phx-component]')?.dataset
      .phxComponent;

    let attr = null;
    let val = null;

    if (!cid) {
      attr = 'id';
      val = socketID;
    } else {
      attr = 'data-phx-component';
      val = cid;
    }

    const highlightEvent = new CustomEvent('live-debugger-inspect-highlight', {
      detail: {
        attr,
        val,
      },
    });

    const pulseEvent = new CustomEvent('live-debugger-inspect-pulse', {
      detail: {
        attr,
        val,
      },
    });

    document.dispatchEvent(highlightEvent);
    document.dispatchEvent(pulseEvent);

    window.open(sessionURL, '_blank');

    disableInspectMode();
  };

  const disableInspectMode = () => {
    if (!inspectMode) {
      return;
    }

    inspectMode = false;
    document.body.classList.remove('force-cursor-crosshair');
    document.body.removeEventListener('click', handleInspect);
    document.body.removeEventListener('mouseover', handleMove);
  };

  const enableInspectMode = () => {
    if (inspectMode) {
      return;
    }

    inspectMode = true;
    document.body.classList.add('force-cursor-crosshair');
    document.body.addEventListener('click', handleInspect);
    document.body.addEventListener('mouseover', handleMove);
    console.log('Inspect mode enabled');
  };

  document.addEventListener('live-debugger-debug-button-inspect', (event) => {
    setTimeout(enableInspectMode);
  });
}
