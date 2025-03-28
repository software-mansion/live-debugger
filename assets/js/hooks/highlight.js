const Highlight = {
  mounted() {
    const highlightSwitch = document.querySelector('#highlight-switch');
    let params = {};

    this.pushHighlight = (e) => {
      if (highlightSwitch.checked) {
        const attr = e.target.attributes;

        params = {
          search_attribute: attr['phx-value-search-attribute'].value,
          search_value: attr['phx-value-search-value'].value,
        };

        this.pushEventTo('#sidebar', 'highlight', params);
      }
    };

    if (highlightSwitch) {
      this.el.addEventListener('mouseenter', this.pushHighlight);
      this.el.addEventListener('mouseleave', this.pushHighlight);
    }
  },
  destroyed() {
    this.el.removeEventListener('mouseenter', this.pushHighlight);
    this.el.removeEventListener('mouseleave', this.pushHighlight);
  },
};

export default Highlight;
