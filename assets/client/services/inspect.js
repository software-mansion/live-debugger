import { dispatchCustomEvent } from '../utils/dom';

export default function initElementInspection({ baseURL }) {
  let inspectMode = false;
  let lastID = null;

  const handleMove = (event) => {
    const live_view_element = event.target.closest('[data-phx-session]');
    const component_element = event.target.closest('[data-phx-component]');
    const detail = getHighlightDetail(component_element, live_view_element);

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
    const root_element = document.querySelector('[data-phx-main]');

    if (!live_view_element) {
      return;
    }

    const detail = getHighlightDetail(component_element, live_view_element);
    pushPulseEvent(detail);

    const url = new URL(`${baseURL}/redirect/${live_view_element.id}`);

    if (live_view_element.id !== root_element.id) {
      url.searchParams.set('root_id', root_element.id);
    }

    if (detail.type === 'component') {
      url.searchParams.set('node_id', component_element.dataset.phxComponent);
    }

    window.open(url, '_blank');

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

function pushClearEvent() {
  dispatchCustomEvent('lvdbg:inspect-clear');
}

function getHighlightDetail(component_element, live_view_element) {
  const return_live_view = {
    attr: 'id',
    val: live_view_element?.id,
    type: 'live_view',
  };

  const return_component = {
    attr: 'data-phx-id',
    val: `c${component_element?.dataset.phxComponent}-${live_view_element?.id}`,
    type: 'component',
  };

  if (!component_element) {
    return return_live_view;
  }

  if (live_view_element.contains(component_element)) {
    return return_component;
  }

  return return_live_view;
}
