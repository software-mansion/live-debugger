const CloseSidebarOnResize = {
  mounted() {
    this.wasOpen = this.isOpen();

    this.observer = new ResizeObserver(() => {
      const nowOpen = this.isOpen();
      if (this.wasOpen && !nowOpen) {
        const cmd = this.el.dataset.cmd;
        if (cmd) {
          this.liveSocket.execJS(this.el, cmd);
        }
      }

      this.wasOpen = nowOpen;
    });

    this.observer.observe(document.body);

    window.addEventListener('resize', this.checkBreakpoint);
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },

  isOpen() {
    const styles = getComputedStyle(this.el);
    const value = styles
      .getPropertyValue('--sidebar-open')
      .trim()
      .replace(/['"]/g, '');

    return value === '1';
  },
};

export default CloseSidebarOnResize;
