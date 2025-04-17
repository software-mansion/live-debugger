const TraceExecutionTime = {
  mounted() {
    let start = Date.now();
    let current = start;

    this.intervalId = setInterval(() => {
      current = Date.now() - start;

      this.el.textContent = current + ' ms';
    }, 16);
  },
  updated() {
    clearInterval(this.intervalId);
  },
};

export default TraceExecutionTime;
