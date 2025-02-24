// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';
import Alpine from 'alpinejs';
import collapse from '@alpinejs/collapse';
import Hooks from './hooks';

Alpine.start();
Alpine.plugin(collapse);
window.Alpine = Alpine;

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

window.addEventListener('phx:historical-events', (e) => {
  const tracesListDiv = document.querySelector(
    `#${e.detail.trace_list_dom_id}`
  );
  let separator = document.querySelector('#separator');

  if (separator) {
    tracesListDiv.removeChild(separator);
  } else {
    separator = document.createElement('div');
    separator.id = 'separator';
    separator.innerHTML = `
      Historical events
      <div class="border-b h-0 border-primary-100"></div>
    `;
  }

  if (!e.detail.trace_list_empty) {
    tracesListDiv.prepend(separator);
  }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
