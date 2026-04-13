const OVERLAY_ID = 'tour-overlay';
const PENDING_ACTION_KEY = 'lvdbg-tour-pending';

function clearAll() {
  const overlay = document.getElementById(OVERLAY_ID);
  if (overlay) overlay.remove();

  document
    .querySelectorAll('.tour-highlight, .tour-spotlight-target')
    .forEach((el) => {
      el.classList.remove('tour-highlight', 'tour-spotlight-target');
    });
}

function highlight(target) {
  target.scrollIntoView({
    behavior: 'smooth',
    block: 'center',
  });
  target.classList.add('tour-highlight');
}

function createOverlay() {
  if (!document.getElementById(OVERLAY_ID)) {
    const overlay = document.createElement('div');
    overlay.id = OVERLAY_ID;
    overlay.className = 'tour-overlay';
    document.body.appendChild(overlay);
  }
}

function spotlight(target) {
  createOverlay();

  target.scrollIntoView({
    behavior: 'smooth',
    block: 'center',
  });
  target.classList.add('tour-spotlight-target');
}

const Tour = {
  mounted() {
    this._cleanup = null;

    const pending = sessionStorage.getItem(PENDING_ACTION_KEY);
    if (pending) {
      sessionStorage.removeItem(PENDING_ACTION_KEY);
      this._applyAction(JSON.parse(pending));
    }

    this.handleEvent('tour-action', (payload) => {
      this._applyAction(payload);
    });
  },

  _applyAction(payload) {
    const {
      action,
      target: selector,
      dismiss,
      url,
      then: nextAction,
    } = payload;

    this._cleanupListeners();
    clearAll();

    if (action === 'clear') return;

    if (action === 'redirect') {
      if (nextAction) {
        sessionStorage.setItem(PENDING_ACTION_KEY, JSON.stringify(nextAction));
      }
      this.pushEvent('tour-redirect', { url });
      return;
    }

    const target = document.querySelector(selector);
    if (!target) {
      this._waitForTarget(selector, () =>
        this._applyToTarget(selector, payload)
      );
      return;
    }

    this._applyToTarget(selector, payload);
  },

  _applyToTarget(selector, payload) {
    const { action, dismiss } = payload;
    const target = document.querySelector(selector);
    if (!target) return;

    switch (action) {
      case 'highlight':
        highlight(target);
        break;
      case 'spotlight':
        spotlight(target);
        break;
      default:
        console.warn(`[Tour] Unknown action: ${action}`);
        return;
    }

    if (dismiss === 'click-anywhere') {
      this._setupClickAnywhereDismiss();
    } else if (dismiss === 'click-target') {
      this._setupClickTargetDismiss(target, selector);
    }
  },

  _waitForTarget(selector, callback) {
    const observer = new MutationObserver(() => {
      // Szukamy elementu używając selektora CSS
      if (document.querySelector(selector)) {
        observer.disconnect();
        callback();
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });

    const prevCleanup = this._cleanup;
    this._cleanup = () => {
      observer.disconnect();
      if (prevCleanup) prevCleanup();
    };
  },

  _cleanupListeners() {
    if (this._cleanup) {
      this._cleanup();
      this._cleanup = null;
    }
  },

  _setupClickAnywhereDismiss() {
    const controller = new AbortController();

    const handler = () => {
      clearAll();
      this._cleanup = null;
      this.pushEvent('step-completed', { target: 'anywhere' });
    };

    this._cleanup = () => controller.abort();

    setTimeout(() => {
      if (!controller.signal.aborted) {
        document.addEventListener('click', handler, {
          once: true,
          signal: controller.signal,
        });
      }
    }, 0);
  },

  _setupClickTargetDismiss(target, selector) {
    const overlay = document.getElementById(OVERLAY_ID);

    const handler = () => {
      clearAll();
      this._cleanup = null;
      this.pushEvent('step-completed', { target: selector });
    };

    const overlayHandler = (e) => e.stopPropagation();
    if (overlay) {
      overlay.addEventListener('click', overlayHandler);
    }

    target.addEventListener('click', handler, { once: true });

    this._cleanup = () => {
      target.removeEventListener('click', handler);
      if (overlay) overlay.removeEventListener('click', overlayHandler);
    };
  },

  destroyed() {
    this._cleanupListeners();
    clearAll();
  },
};

export default Tour;
