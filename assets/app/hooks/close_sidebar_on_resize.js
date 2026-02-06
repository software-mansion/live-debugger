const CloseSidebarOnResize = {
  mounted() {
    this.wasNarrow = this.isNarrowView();
    this.onResize = this.onResize.bind(this);

    window.addEventListener('resize', this.onResize);
  },

  destroyed() {
    window.removeEventListener('resize', this.onResize);
  },

  onResize() {
    const currentlyNarrow = this.isNarrowView();

    if (this.wasNarrow && !currentlyNarrow) {
      const cmd = this.el.dataset.cmd;
      if (cmd) {
        this.liveSocket.execJS(this.el, cmd);
      }
    }

    this.wasNarrow = currentlyNarrow;
  },

  isNarrowView() {
    const styles = getComputedStyle(this.el);
    const value = styles
      .getPropertyValue('--narrow-view')
      .trim()
      .replace(/['"]/g, '');

    return value === '1';
  },
};

export default CloseSidebarOnResize;
