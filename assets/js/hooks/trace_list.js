TraceList = {
  mounted() {
    this.createSeparator = () => {
      const separator = document.createElement('div');
      separator.id = 'separator';
      separator.innerHTML = `
          <div class="h-6 my-1 font-normal text-xs text-secondary-600 flex align items-center">
            <div class="border-b border-secondary-200 grow"></div>
            <span class="mx-2">Past Traces</span>
            <div class="border-b border-secondary-200 grow"></div>
          </div>
        `;
      return separator;
    };
    this.handleEvent('past-traces-load', () => {
      let separator = this.el.querySelector('#separator');

      if (separator) {
        separator.remove();
      } else {
        separator = this.createSeparator();
      }

      this.el.prepend(separator);
    });
    this.handleEvent('past-traces-clear', () => {
      const separator = this.el.querySelector('#separator');

      if (separator) {
        separator.remove();
      }
    });
    this.handleEvent('switch-tracing', ({ tracing_started }) => {
      if (tracing_started) {
        let separator = this.el.querySelector('#separator');

        if (separator) {
          separator.remove();
          this.el.prepend(separator);
        }
      }
    });
    this.handleEvent('start-tracing', () => {
      let separator = this.el.querySelector('#separator');

      if (separator) {
        separator.remove();
      } else {
        separator = this.createSeparator();
      }
      this.el.prepend(separator);
    });
  },
};

export default TraceList;
