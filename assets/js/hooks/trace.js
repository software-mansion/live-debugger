const Trace = {
  mounted() {
    let start = Date.now();
    let current = start;

    this.id = setInterval(() => {
      current = Date.now() - start;

      this.el.textContent = current + ' ms';
      console.log(current);
    }, 16);
  },
  updated() {
    console.log('updated');
    clearInterval(this.id);
  },
};

export default Trace;
