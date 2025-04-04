const LiveDropdown = {
  mounted() {
    const dropdownId = this.el.id.replace('-live-dropdown-container', '');
    const contentId = `${dropdownId}-content`;
    this.contentEl = document.getElementById(contentId);

    function isHidden(el) {
      return el.classList.contains('hidden');
    }

    function isClickOutside(event, el) {
      return !el.contains(event.target);
    }

    this.handleClick = (event) => {
      if (!isHidden(this.contentEl) && isClickOutside(event, this.contentEl)) {
        this.pushEventTo(`#${this.el.id}`, 'close', {});
      }
    };

    document.addEventListener('click', this.handleClick);
  },

  destroyed() {
    document.removeEventListener('click', this.handleClick);
  },
};

export default LiveDropdown;
