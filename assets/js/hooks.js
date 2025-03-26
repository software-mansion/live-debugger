import Alpine from 'alpinejs';
import collapse from '@alpinejs/collapse';

import CollapsibleOpen from './hooks/collapsible_open';
import Fullscreen from './hooks/fullscreen';
import Tooltip from './hooks/tooltip';
import topbar from '../vendor/topbar';

Alpine.start();
Alpine.plugin(collapse);
window.Alpine = Alpine;

topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

function createHooks() {
  return {
    CollapsibleOpen,
    Fullscreen,
    Tooltip,
  };
}

window.createHooks = createHooks;
