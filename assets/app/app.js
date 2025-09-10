import Alpine from 'alpinejs';
import collapse from '@alpinejs/collapse';

import Collapsible from './hooks/collapsible';
import Fullscreen from './hooks/fullscreen';
import ToggleTheme from './hooks/toggle_theme';
import Tooltip from './hooks/tooltip';
import Highlight from './hooks/highlight';
import LiveDropdown from './hooks/live_dropdown';
import AutoClearFlash from './hooks/auto_clear_flash';
import TraceExecutionTime from './hooks/trace_execution_time';
import CopyButton from './hooks/copy_button';
import TraceBodySearchHighlight from './hooks/trace_body_search_highlight';
import TraceLabelSearchHighlight from './hooks/trace_label_search_highlight';

import topbar from './vendor/topbar';

Alpine.start();
Alpine.plugin(collapse);
window.Alpine = Alpine;

topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

function createHooks() {
  return {
    Collapsible,
    Fullscreen,
    Tooltip,
    ToggleTheme,
    Highlight,
    LiveDropdown,
    AutoClearFlash,
    TraceExecutionTime,
    CopyButton,
    TraceBodySearchHighlight,
    TraceLabelSearchHighlight,
  };
}

function saveDialogAndDetailsState() {
  return (fromEl, toEl) => {
    if (['DIALOG', 'DETAILS'].indexOf(fromEl.tagName) >= 0) {
      Array.from(fromEl.attributes).forEach((attr) => {
        toEl.setAttribute(attr.name, attr.value);
      });
    }
  };
}

function setTheme() {
  // Check system preferences for dark mode, and add the .dark class to the body if it's dark
  switch (localStorage.theme) {
    case 'light':
      document.documentElement.classList.remove('dark');
      break;
    case 'dark':
      document.documentElement.classList.add('dark');
      break;
    default:
      const prefersDarkScheme = window.matchMedia(
        '(prefers-color-scheme: dark)'
      ).matches;

      document.documentElement.classList.toggle('dark', prefersDarkScheme);
      localStorage.theme = prefersDarkScheme ? 'dark' : 'light';
      break;
  }
}

function getCsrfToken() {
  return document
    .querySelector("meta[name='csrf-token']")
    .getAttribute('content');
}

function handleStorage(e) {
  if (e.key !== 'theme') return;
  document.documentElement.classList.toggle('dark', e.newValue === 'dark');
};

window.addEventListener('storage', handleStorage);

window.createHooks = createHooks;
window.setTheme = setTheme;
window.getCsrfToken = getCsrfToken;
window.saveDialogAndDetailsState = saveDialogAndDetailsState;
