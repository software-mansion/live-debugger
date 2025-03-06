TraceList = {
  mounted() {
    this.handleEvent('historical-events-load', () => {
      let separator = document.querySelector('#separator');

      if (separator) {
        this.el.removeChild(separator);
      } else {
        separator = document.createElement('div');
        separator.id = 'separator';
        separator.innerHTML = `
          <div class="px-6 py-1 font-normal text-center text-xs border-y border-secondary-200">Historical events</div>
        `;
      }

      this.el.prepend(separator);
    });
    this.handleEvent('historical-events-clear', () => {
      const separator = document.querySelector('#separator');
      if (separator) {
        this.el.removeChild(separator);
      }
    });
  },
};

export default TraceList;
