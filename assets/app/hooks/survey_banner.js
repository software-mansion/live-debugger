const SurveyBanner = {
  counterThreshold: 100,
  mounted() {
    this.handleVersion(this.el.dataset.currentVersion);

    if (localStorage.getItem('lvdbg:survey-dismissed')) return;

    const counter = Number(localStorage.getItem('lvdbg:survey-counter'));

    if (counter < this.counterThreshold) {
      localStorage.setItem('lvdbg:survey-counter', counter + 1);
    } else {
      this.showBanner();
    }
  },
  handleVersion(currentVersion) {
    const lastVersion = localStorage.getItem('lvdbg:last-version');

    if (currentVersion !== lastVersion) {
      localStorage.setItem('lvdbg:last-version', currentVersion);
      localStorage.setItem('lvdbg:survey-counter', 0);
      localStorage.removeItem('lvdbg:survey-dismissed');
    }
  },
  showBanner() {
    this.el.querySelector('button').addEventListener('click', () => {
      localStorage.setItem('lvdbg:survey-dismissed', true);
    });

    this.el.classList.remove('hidden');
  },
};

export default SurveyBanner;
