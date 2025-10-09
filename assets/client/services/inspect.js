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
      sourceLiveViews = sourceLiveViews.filter((pid) => pid !== event.pid);

      if (sourceLiveViews.length === 0) {
        disableInspectMode();
      }
    }
  });

  const handleMove = (event) => {
    const elementInfo = getClosestElementInfo(event.target);

    if (!elementInfo) {
      return;
    }

    const detail = getHighlightDetail(elementInfo);

    if (detail.val === lastID) {
      return;
    }

    const id =
      elementInfo.type == 'LiveComponent'
        ? elementInfo.element.dataset.phxComponent
        : elementInfo.element.id;

    debugChannel.push('request-node-element', {
      root_socket_id: socketID,
      socket_id: elementInfo.phxId,
      type: elementInfo.type,
      id,
    });

    lastID = detail.val;

    pushHighlightEvent({
      attr: detail.attr,
      val: detail.val,
      type: elementInfo.type,
    });
  };

  const handleInspect = (event) => {
    event.preventDefault();
    event.stopPropagation();

    const elementInfo = getClosestElementInfo(event.target);

    if (!elementInfo) {
      return;
    }

    const detail = getHighlightDetail(elementInfo);

    pushPulseEvent({
      attr: detail.attr,
      val: detail.val,
      type: elementInfo.type,
    });

    const url = getElementURL(baseURL, elementInfo);

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

    sourceLiveViews = [];
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

    sourceLiveViews = [];
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

      sourceLiveViews = [];
      disableInspectMode();
    }
  };

  const handleMouseLeave = () => {
    pushClearEvent();
    lastID = null;
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
    document.removeEventListener('mouseleave', handleMouseLeave);
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
    document.body.addEventListener('mouseleave', handleMouseLeave);
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

function getClosestElementInfo(target) {
  const liveViewElement = target.closest('[data-phx-session]');
  const componentElement = target.closest('[data-phx-component]');
  const rootElement = document.querySelector('[data-phx-main]');

  if (componentElement && liveViewElement.contains(componentElement)) {
    return {
      element: componentElement,
      type: 'LiveComponent',
      phxRootId: rootElement.id,
      phxId: liveViewElement.id,
    };
  }

  return {
    element: liveViewElement,
    type: 'LiveView',
    phxRootId: rootElement.id,
    phxId: liveViewElement.id,
  };
}

function getElementURL(baseURL, { element, type, phxRootId, phxId }) {
  const url = new URL(`${baseURL}/redirect/${phxId}`);

  if (phxRootId !== phxId) {
    url.searchParams.set('root_id', phxRootId);
  }

  if (type === 'LiveComponent') {
    url.searchParams.set('node_id', element.dataset.phxComponent);
  }

  return url;
}

function getHighlightDetail({ type, element, phxId }) {
  if (type === 'LiveComponent') {
    return {
      attr: 'data-phx-id',
      val: `c${element.dataset.phxComponent}-${phxId}`,
    };
  }

  return {
    attr: 'id',
    val: element.id,
  };
}
