const Highlight = {
  mounted() {
    const highlightSwitch = document.querySelector('#highlight-switch');
    let params = {};

    this.pushHighlight = (e) => {
      if (highlightSwitch.checked) {
        params = {
          search_attribute:
            e.target.attributes['phx-value-search_attribute'].value,
          search_value: e.target.attributes['phx-value-search_value'].value,
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
