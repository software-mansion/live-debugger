const LiveDropdown = {
  mounted() {
    const dropdownId = this.el.id.replace('-live-dropdown-container', '');
    this.contentId = `${dropdownId}-content`;

    function isHidden(el) {
      return el.classList.contains('hidden');
    }

    function isClickOutside(event, el) {
      return !el.contains(event.target);
    }

    this.handleClick = (event) => {
      const contentEl = document.getElementById(this.contentId);
      if (!contentEl) {
        return;
      }

      if (!isHidden(contentEl) && isClickOutside(event, contentEl)) {
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
