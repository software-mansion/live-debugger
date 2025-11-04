// This hook is resonsible for adding a pulse animation to an element
// whenever its updated and it has the data-pulse attribute set.
// Somewhat convoluted logic aims to reset the animation if update is triggered
// before previous animation is complete.
const DiffPulse = {
  mounted() {
    if (this.el.hasAttribute('data-pulse')) {
      this.el.removeAttribute('data-pulse');

      this.el.classList.add('animate-diff-pulse');

      this.timeout = setTimeout(() => {
        this.el.classList.remove('animate-diff-pulse');
      }, 500);
    }
  },
  updated() {
    if (this.el.hasAttribute('data-pulse')) {
      clearTimeout(this.timeout);
      this.el.removeAttribute('data-pulse');
      this.el.classList.remove('animate-diff-pulse');

      setTimeout(() => this.el.classList.add('animate-diff-pulse'));

      this.timeout = setTimeout(() => {
        this.el.classList.remove('animate-diff-pulse');
      }, 500);
    }
  },
  destroyed() {
    clearTimeout(this.timeout);
  },
};

export default DiffPulse;
