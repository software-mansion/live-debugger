const Dropdown = {
  mounted() {
    const contentId = `${this.el.id.replace('-button', '')}-content`;
    this.contentEl = document.getElementById(contentId);

    function isHidden(el) {
      return el.classList.contains('hidden');
    }

    function isClickOutside(event, el) {
      return !el.contains(event.target);
    }

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
  },
};

export default Dropdown;
