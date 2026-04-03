const OVERLAY_ID = 'tour-overlay';

function getTarget(id) {
  const el = document.getElementById(id);
  if (!el) {
    console.warn(`[Tour] Element #${id} not found`);
  }
  return el;
}

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
  target.classList.add('tour-spotlight-target');
}

const Tour = {
  mounted() {
    this._cleanup = null;
    this._appliedKey = null;

    this._applyFromData();

    this.handleEvent('tour-action', (payload) => {
      this._applyAction(payload);
    });
  },

  updated() {
    this._applyFromData();
  },

  _applyFromData() {
    const action = this.el.dataset.tourAction;
    if (!action) return;

    const payload = {
      action,
      target: this.el.dataset.tourTarget,
      dismiss: this.el.dataset.tourDismiss,
    };

    console.log({ payload });

    const key = `${action}:${payload.target}:${payload.dismiss}`;
    console.log({ key });
    if (this._appliedKey === key) return;

    this._applyAction(payload);
  },

  _applyAction(payload) {
    const { action, target: targetId, dismiss } = payload;

    this._cleanupListeners();
    clearAll();

    this._appliedKey = `${action}:${targetId}:${dismiss}`;

    if (action === 'clear') return;

    const target = document.getElementById(targetId);
    if (!target) {
      this._waitForTarget(targetId, () =>
        this._applyToTarget(targetId, payload)
      );
      return;
    }

    this._applyToTarget(targetId, payload);
  },

  _applyToTarget(targetId, payload) {
    const { action, dismiss } = payload;
    const target = document.getElementById(targetId);
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
      this._setupClickTargetDismiss(target, targetId);
    }
  },

  _waitForTarget(targetId, callback) {
    const observer = new MutationObserver(() => {
      if (document.getElementById(targetId)) {
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
    const handler = () => {
      clearAll();
      this._cleanup = null;
    };

    setTimeout(() => {
      document.addEventListener('click', handler, { once: true });
      this._cleanup = () => document.removeEventListener('click', handler);
    }, 0);
  },

  _setupClickTargetDismiss(target, targetId) {
    const overlay = document.getElementById(OVERLAY_ID);

    const handler = () => {
      clearAll();
      this._cleanup = null;
      this.pushEvent('step-completed', { target: targetId });
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
