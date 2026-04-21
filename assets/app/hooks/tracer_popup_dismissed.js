const STORAGE_KEY = 'lvdbg:tracer-popup-dismissed';

const TracerPopupDismissed = {
  updateVisibility(show) {
    if (show) {
      this.el.classList.remove('hidden');
    } else {
      this.el.classList.add('hidden');
    }
  },
  mounted() {
    this.updateVisibility(!sessionStorage.getItem(STORAGE_KEY));

    this.handleEvent('set_dismissed', () => {
      sessionStorage.setItem(STORAGE_KEY, 'true');
      this.updateVisibility(false);
    });

    this.handleEvent('clear_dismissed', () => {
      sessionStorage.removeItem(STORAGE_KEY);
      this.updateVisibility(true);
    });
  },
};

export default TracerPopupDismissed;
