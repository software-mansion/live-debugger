const Highlight = {
  mounted() {
    const highlightSwitch = document.querySelector('[data-highlight]');
    let params = {};

    this.pushHighlight = (e) => {
      if (highlightSwitch.dataset.highlight === 'on') {
        params = {
          search_attribute: e.target.dataset.search_attribute,
          search_value: e.target.dataset.search_value,
        };
        this.pushEvent('highlight', params);
      }
    };

    this.el.addEventListener('mouseenter', this.pushHighlight);
    this.el.addEventListener('mouseleave', this.pushHighlight);
  },
  destroyed() {
    this.el.removeEventListener('mouseenter', this.pushHighlight);
    this.el.removeEventListener('mouseleave', this.pushHighlight);
  },
};

export default Highlight;
