const Dropdown = {
  mounted() {
    const contentId = `${this.el.id.replace('-button', '')}-content`;
    this.contentEl = document.getElementById(contentId);

    this.handleClick = () => {
      if (this.contentEl.classList.contains('hidden')) {
        this.contentEl.classList.remove('hidden');
        this.contentEl.classList.add('block');
      } else {
        this.contentEl.classList.add('hidden');
        this.contentEl.classList.remove('block');
      }
    };

    this.el.addEventListener('click', this.handleClick);
  },
};

export default Dropdown;
