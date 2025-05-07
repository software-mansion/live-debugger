const TraceExecutionTime = {
  mounted() {
    let start = Date.now();
    let current = start;
    let handled = false;

    this.intervalId = setInterval(() => {
      current = Date.now() - start;
      this.el.textContent = current + ' ms';
    }, 16);

    this.handleEvent('stop-timer', () => {
      if (!handled) {
        clearInterval(this.intervalId);
        this.el.closest('details').open = false;
      }
    });
  },
};

export default TraceExecutionTime;
