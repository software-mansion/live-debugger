import { dispatchCustomEvent } from '../utils/dom';

export default function initElementInspection({ baseURL }) {
  let inspectMode = false;
  let lastID = null;

  const handleMove = (event) => {
    const live_view_element = event.target.closest('[data-phx-session]');
    const component_element = event.target.closest('[data-phx-component]');

    const detail = getHighlightDetail(component_element, live_view_element);
    console.log(detail);

    console.log(detail);

    if (detail.val === lastID) {
      return;
    }

    lastID = detail.val;

    pushHighlightEvent(detail);
  };

  const handleInspect = (event) => {
    event.preventDefault();
    event.stopPropagation();

    const live_view_element = event.target.closest('[data-phx-session]');
    const component_element = event.target.closest('[data-phx-component]');

    const detail = getHighlightDetail(component_element, live_view_element);

    pushPulseEvent(detail);

    // window.open(baseURL + (cid ? `?node_id=${detail.val}` : ''), '_blank');

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

function getHighlightDetail(component_element, live_view_element) {
  const return_live_view = {
    attr: 'id',
    val: live_view_element?.id,
  };

  const return_component = {
    attr: 'data-phx-id',
    val: `c${component_element?.dataset.phxComponent}-${live_view_element?.id}`,
  };

  if (!component_element) {
    return return_live_view;
  }

  if (!live_view_element) {
    return return_component;
  }

  if (live_view_element.contains(component_element)) {
    return return_component;
  }

  return return_live_view;
}

function pushClearEvent() {
  dispatchCustomEvent('lvdbg:inspect-clear');
}
