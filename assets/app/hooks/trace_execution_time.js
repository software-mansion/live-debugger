function parseElapsedTime(ms) {
  if (ms < 1000) return ms + ' ms';
  return (ms / 1000).toFixed(2) + ' s';
}

const TraceExecutionTime = {
  mounted() {
    let start = Date.now();
    let current = start;
    let handled = false;

    this.intervalId = setInterval(() => {
      current = Date.now() - start;
      this.el.textContent = parseElapsedTime(current);
    }, 16);

    this.handleEvent('stop-timer', () => {
      if (!handled) {
        clearInterval(this.intervalId);
        this.el.closest('details').open = false;
        handled = true;
      }
    });
  },
  destroyed() {
    clearInterval(this.intervalId);
  },
};

export default TraceExecutionTime;
