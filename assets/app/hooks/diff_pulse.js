const DiffPulse = {
  mounted() {
    console.log('mounted');
    if (this.el.hasAttribute('data-pulse')) {
      console.log('mounted');
      this.el.removeAttribute('data-pulse');

      this.el.classList.add('animate-diff-pulse');

      this.timeout = setTimeout(() => {
        this.el.classList.remove('animate-diff-pulse');
      }, 500);
    }
  },
  updated() {
    if (this.el.hasAttribute('data-pulse')) {
      console.log('updated', this.el.textContent);
      clearTimeout(this.timeout);
      this.el.removeAttribute('data-pulse');
      this.el.classList.remove('animate-diff-pulse');

      setTimeout(() => this.el.classList.add('animate-diff-pulse'));

      this.timeout = setTimeout(() => {
        this.el.classList.remove('animate-diff-pulse');
      }, 1500);
    }
  },
  destroyed() {
    console.log('destroyed');
    clearTimeout(this.timeout);
  },
};

export default DiffPulse;
