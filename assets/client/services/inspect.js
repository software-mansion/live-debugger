import { dispatchCustomEvent } from '../utils/dom';

export default function initElementInspection({
  baseURL,
  debugChannel,
  socketID,
}) {
  let inspectMode = false;
  let lastID = null;
  let sourceLiveViews = [];

  debugChannel.on('found-node-element', (event) => {
    pushShowTooltipEvent({
      module: event.module,
      type: event.type,
      id_key: event.id_key,
      id_value: event.id_value,
    });
  });

  debugChannel.on('inspect-mode-changed', (event) => {
    if (event.inspect_mode) {
      enableInspectMode();
      sourceLiveViews.push(event.pid);
    } else {
      disableInspectMode();
      sourceLiveViews = sourceLiveViews.filter((pid) => pid !== event.pid);
    }
  });
  const handleMove = (event) => {
    const liveViewElement = event.target.closest('[data-phx-session]');
    const componentElement = event.target.closest('[data-phx-component]');

    if (!liveViewElement) {
      return;
    }

    const detail = getHighlightDetail(componentElement, liveViewElement);

    if (detail.val === lastID) {
      return;
    }

    const type = detail.attr === 'id' ? 'LiveView' : 'LiveComponent';
    const id =
      detail.attr === 'id' ? detail.val : componentElement.dataset.phxComponent;

    debugChannel.push('request-node-element', {
      root_socket_id: socketID,
      socket_id: liveViewElement.id,
      type,
      id,
    });

    lastID = detail.val;

    pushHighlightEvent({ attr: detail.attr, val: detail.val, type });
  };

  const handleInspect = (event) => {
    event.preventDefault();
    event.stopPropagation();

    const liveViewElement = event.target.closest('[data-phx-session]');
    const componentElement = event.target.closest('[data-phx-component]');
    const rootElement = document.querySelector('[data-phx-main]');

    if (!liveViewElement) {
      return;
    }

    const rootID = rootElement?.id || liveViewElement.dataset.phxRootId;

    const detail = getHighlightDetail(componentElement, liveViewElement);
    pushPulseEvent(detail);

    const url = new URL(`${baseURL}/redirect/${liveViewElement.id}`);

    if (liveViewElement.id !== rootID) {
      url.searchParams.set('root_id', rootID);
    }

    if (componentElement) {
      url.searchParams.set('node_id', componentElement.dataset.phxComponent);
    }

    if (sourceLiveViews.length === 0) {
      window.open(url, '_blank');
    } else {
      sourceLiveViews.forEach((pid) => {
        debugChannel.push('element-inspected', {
          pid: pid,
          url: url,
        });
      });
    }

    disableInspectMode();
  };

  const handleRightClick = (event) => {
    event.preventDefault();

    sourceLiveViews.forEach((pid) => {
      debugChannel.push('inspect-mode-changed', {
        inspect_mode: false,
        pid: pid,
      });
    });

    disableInspectMode();
  };

  const handleEscape = (event) => {
    if (event.key === 'Escape') {
      sourceLiveViews.forEach((pid) => {
        debugChannel.push('inspect-mode-changed', {
          inspect_mode: false,
          pid: pid,
        });
      });

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
    pushRemoveTooltipEvent();

    document.body.classList.remove('live-debugger-inspect-mode');
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

    document.body.classList.add('live-debugger-inspect-mode');
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
  dispatchCustomEvent('lvdbg:inspect-highlight', {
    detail,
  });
}

function pushPulseEvent(detail) {
  dispatchCustomEvent('lvdbg:inspect-pulse', {
    detail,
  });
}

function pushClearEvent() {
  dispatchCustomEvent('lvdbg:inspect-clear');
}

function pushShowTooltipEvent(detail) {
  dispatchCustomEvent('lvdbg:show-tooltip', {
    detail,
  });
}

function pushRemoveTooltipEvent() {
  dispatchCustomEvent('lvdbg:remove-tooltip');
}

function getHighlightDetail(componentElement, liveViewElement) {
  if (componentElement && liveViewElement.contains(componentElement)) {
    return {
      attr: 'data-phx-id',
      val: `c${componentElement.dataset.phxComponent}-${liveViewElement.id}`,
    };
  }

  return {
    attr: 'id',
    val: liveViewElement.id,
  };
}
