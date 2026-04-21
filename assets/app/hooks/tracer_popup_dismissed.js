const STORAGE_KEY = 'lvdbg:tracer-dismissed';

const TracerPopupDismissed = {
  sendDismissed(dismissed) {
    this.pushEventTo(this.el, 'dismissed', { dismissed });
  },
  mounted() {
    this.sendDismissed(!!sessionStorage.getItem(STORAGE_KEY));

    this.handleEvent('set_dismissed', () => {
      sessionStorage.setItem(STORAGE_KEY, true);
      this.sendDismissed(true);
    });

    this.handleEvent('clear_dismissed', () => {
      sessionStorage.removeItem(STORAGE_KEY);
      this.sendDismissed(false);
    });
  },
};

export default TracerPopupDismissed;
