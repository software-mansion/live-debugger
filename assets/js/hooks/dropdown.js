const Dropdown = {
  mounted() {
    const dropdownId = this.el.id.replace('-button', '');
    const contentId = `${dropdownId}-content`;
    this.contentEl = document.getElementById(contentId);

    function isHidden(el) {
      return el.classList.contains('hidden');
    }

    function isClickOutside(event, el) {
      return !el.contains(event.target);
    }

    // Event from the browser
    this.el.addEventListener('click', (event) => {
      if (isHidden(this.contentEl)) {
        this.contentEl.classList.remove('hidden');
      } else {
        this.contentEl.classList.add('hidden');
      }

      event.stopPropagation();
    });

    document.addEventListener('click', (event) => {
      if (!isHidden(this.contentEl) && isClickOutside(event, this.contentEl)) {
        this.contentEl.classList.add('hidden');
      }

      document.removeEventListener('click', this.handleClick);
    });

    // Event from the server
    this.handleEvent(`${dropdownId}-close`, () => {
      this.contentEl.classList.add('hidden');
    });
  },
};

export default Dropdown;
