import Alpine from 'alpinejs';
import collapse from '@alpinejs/collapse';
import lt from 'semver/functions/lt';

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
import AssignsBodySearchHighlight from './hooks/assigns_body_search_highlight';
import DiffPulse from './hooks/diff_pulse';
import ChartHook from './hooks/chart_hook';
import CollapsedSectionPulse from './hooks/collapsed_section_pulse';
import OpenComponentsTree from './hooks/open_components_tree';
import CloseSidebarOnResize from './hooks/close_sidebar_on_resize';
import CodeMirrorTextarea from './hooks/code_mirror_textarea';
import SurveyBanner from './hooks/survey_banner';

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
    AssignsBodySearchHighlight,
    DiffPulse,
    ChartHook,
    CollapsedSectionPulse,
    CodeMirrorTextarea,
    OpenComponentsTree,
    CloseSidebarOnResize,
    SurveyBanner,
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
  switch (localStorage.getItem('lvdbg:theme')) {
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
      localStorage.setItem('lvdbg:theme', prefersDarkScheme ? 'dark' : 'light');
      break;
  }
}

async function checkForUpdate(currentVersion) {
  const shouldShowPopup = (latestVersion) => {
    const isOlder = lt(currentVersion, latestVersion);
    const isNotIgnored = localStorage.getItem('lvdbg:ignored-version') !== latestVersion;

    return isOlder && isNotIgnored;
  };

  const showPopup = (latestVersion) => {
    const versionSpan = document.getElementById('new-version-popup-version');
    const ignoreCheckbox = document.getElementById('ignore-checkbox');
    const newVersionPopup = document.getElementById('new-version-popup');

    versionSpan.innerText = latestVersion;
    ignoreCheckbox.checked = false;
    ignoreCheckbox.addEventListener('change', (e) => {
      if (e.target.checked) {
        localStorage.setItem('lvdbg:ignored-version', latestVersion);
      } else {
        localStorage.removeItem('lvdbg:ignored-version');
      }
    });

    newVersionPopup.classList.remove('hidden');
  };

  if (sessionStorage.getItem('lvdbg:latest-version')) {
    return;
  }

  const response = await fetch(
    'https://live-debugger.swmansion.com/version/latest'
  );

  const data = await response.json();
  const latestVersion = data.version;

  if (shouldShowPopup(latestVersion)) {
    showPopup(latestVersion);
  }

  sessionStorage.setItem('lvdbg:latest-version', latestVersion);
}

function getCsrfToken() {
  return document
    .querySelector("meta[name='csrf-token']")
    .getAttribute('content');
}

function handleStorage(e) {
  if (e.key !== 'lvdbg:theme') return;
  document.documentElement.classList.toggle('dark', e.newValue === 'dark');
}
//This is needed only for Chrome to refresh the icon after changing the theme.
function handleFaviconRefresh() {
  const favicon = document.querySelector('link[rel="icon"]');
  if (favicon) {
    const cleanHref = favicon.href.split('?')[0];

    favicon.href = `${cleanHref}?v=${new Date().getTime()}`;
  }
}

window.addEventListener('storage', handleStorage);

window.createHooks = createHooks;
window.setTheme = setTheme;
window.checkForUpdate = checkForUpdate;
window.getCsrfToken = getCsrfToken;
window.saveDialogAndDetailsState = saveDialogAndDetailsState;

window
  .matchMedia('(prefers-color-scheme: dark)')
  .addEventListener('change', handleFaviconRefresh);
