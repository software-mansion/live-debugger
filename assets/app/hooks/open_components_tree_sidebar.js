const OpenComponentsTree = {
  mounted() {
    const styles = getComputedStyle(this.el);

    const open = styles.getPropertyValue('--open-sidebar').trim();

    if (open === '"1"' || open === '1') {
      const cmd = this.el.dataset.cmd;
      if (cmd) {
        this.liveSocket.execJS(this.el, cmd);
      }
      //Remove the 'from' query parameter from the URL to avoid opening sidebar on refresh
      const url = new URL(window.location);
      if (url.searchParams.has('from')) {
        url.searchParams.delete('from');
        window.history.replaceState({}, '', url);
      }
    }
  },
};

export default OpenComponentsTree;
