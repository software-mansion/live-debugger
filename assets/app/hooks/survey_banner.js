const SurveyBanner = {
  dismissDuration: 1000 * 60 * 60 * 24,
  mounted() {
    const lastDismissed = localStorage.getItem('lvdbg:survey-dismissed-date');

    if (
      lastDismissed &&
      Date.now() - Number(lastDismissed) < this.dismissDuration
    ) {
      return;
    }

    this.el.querySelector('button').addEventListener('click', () => {
      localStorage.setItem('lvdbg:survey-dismissed-date', Date.now());
    });

    this.el.classList.remove('hidden');
  },
};

export default SurveyBanner;
