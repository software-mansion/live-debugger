const SurveyBanner = {
  dismissDuration: 1000 * 60 * 60 * 24, // 1 day in miliseconds
  mounted() {
    this.handleVersion(this.el.dataset.currentVersion);

    if (this.exceededDismissCounter()) return;
    if (this.exceededDismissDuration()) return;

    this.el
      .querySelector('button')
      .addEventListener('click', this.saveDismissed);

    this.el.classList.remove('hidden');
  },
  handleVersion(currentVersion) {
    const lastVersion = localStorage.getItem('lvdbg:last-version');

    if (currentVersion !== lastVersion) {
      localStorage.setItem('lvdbg:last-version', currentVersion);
      localStorage.removeItem('lvdbg:survey-dismissed-date', currentVersion);
      localStorage.removeItem('lvdbg:survey-dismissed-counter', currentVersion);
    }
  },
  exceededDismissCounter() {
    const dismissedCounter = localStorage.getItem(
      'lvdbg:survey-dismissed-counter'
    );

    return dismissedCounter ? Number(dismissedCounter) >= 3 : false;
  },
  exceededDismissDuration() {
    const lastDismissed = localStorage.getItem('lvdbg:survey-dismissed-date');

    return lastDismissed
      ? Date.now() - Number(lastDismissed) > this.dismissDuration
      : false;
  },
  saveDismissed() {
    const dismissedCounter = localStorage.getItem(
      'lvdbg:survey-dismissed-counter'
    );
    const newCounterValue = dismissedCounter ? Number(dismissedCounter) + 1 : 1;

    localStorage.setItem('lvdbg:survey-dismissed-counter', newCounterValue);
    localStorage.setItem('lvdbg:survey-dismissed-date', Date.now());
  },
};

export default SurveyBanner;
