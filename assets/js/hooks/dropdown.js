const Dropdown = {
  mounted() {
    const contentId = `${this.el.id.replace('-button', '')}-content`;
    this.contentEl = document.getElementById(contentId);

    this.el.addEventListener('click', (event) => {
      if (this.contentEl.classList.contains('hidden')) {
        this.contentEl.classList.remove('hidden');
      } else {
        this.contentEl.classList.add('hidden');
      }

      event.stopPropagation();
    });

    document.addEventListener('click', () => {
      if (!this.contentEl.classList.contains('hidden')) {
        this.contentEl.classList.add('hidden');
      }

      document.removeEventListener('click', this.handleClick);
    });
  },
};

export default Dropdown;
