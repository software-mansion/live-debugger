const CloseSidebarOnResize = {
  mounted() {
    this.wasMobile = this.isMobileLayout();

    this.observer = new ResizeObserver(() => {
      const currentlyMobile = this.isMobileLayout();

      if (this.wasMobile && !currentlyMobile) {
        const cmd = this.el.dataset.cmd;
        if (cmd) {
          this.liveSocket.execJS(this.el, cmd);
        }
      }

      this.wasMobile = currentlyMobile;
    });

    this.observer.observe(document.body);
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },

  isMobileLayout() {
    const styles = getComputedStyle(this.el);
    const value = styles
      .getPropertyValue('--mobile-layout')
      .trim()
      .replace(/['"]/g, '');

    return value === '1';
  },
};

export default CloseSidebarOnResize;
