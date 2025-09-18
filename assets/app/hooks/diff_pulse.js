const DiffPulse = {
  mounted() {
    this.el.classList.add('animate-diff-pulse');
    this.timeout = setTimeout(() => {
      this.el.classList.remove('animate-diff-pulse');
    }, 500);
  },
  destroyed() {
    clearTimeout(this.timeout);
  },
};

export default DiffPulse;
