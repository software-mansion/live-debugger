import 'phoenix_html';
import topbar from '../vendor/topbar';
import Alpine from 'alpinejs';
import collapse from '@alpinejs/collapse';
import Hooks from './hooks';

function getLiveSocket(LiveSocket, Socket) {
  /* This is solution to hiding Dialog and Details components https://github.com/phoenixframework/phoenix_live_view/issues/2349#issuecomment-1430720906 */
  function saveDialogAndDetailsState() {
    return (fromEl, toEl) => {
      if (['DIALOG', 'DETAILS'].indexOf(fromEl.tagName) >= 0) {
        Array.from(fromEl.attributes).forEach((attr) => {
          toEl.setAttribute(attr.name, attr.value);
        });
      }
    };
  }

  let csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute('content');

  let liveSocket = new LiveSocket('/live', Socket, {
    longPollFallbackMs: 2500,
    params: { _csrf_token: csrfToken },
    hooks: Hooks,
    dom: {
      onBeforeElUpdated: saveDialogAndDetailsState(),
    },
  });

  // connect if there are any LiveViews on the page
  liveSocket.connect();
  // expose liveSocket on window for web console debug logs and latency simulation:
  // >> liveSocket.enableDebug()
  // >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
  // >> liveSocket.disableLatencySim()

  return liveSocket;
}

function getApline() {
  Alpine.start();
  Alpine.plugin(collapse);
  return Alpine;
}

// Show progress bar on live navigation and form submits
(function () {
  'use strict';

  topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
  window.addEventListener('phx:page-loading-start', (_info) =>
    topbar.show(300)
  );
  window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());
}).call(this, window);

export { getLiveSocket, getApline };
