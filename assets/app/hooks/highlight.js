const Highlight = {
  mounted() {
    this.highlighted = false;
    this.liveComponent = this.el.closest('[data-phx-id]');

    const attr = this.el.attributes;

    this.params = {
      'window-id': attr['phx-value-window-id']?.value,
      'search-attribute': attr['phx-value-search-attribute']?.value,
      'search-value': attr['phx-value-search-value'].value,
      type: attr['phx-value-type']?.value,
      module: attr['phx-value-module']?.value,
      id: attr['phx-value-id']?.value,
    };

    this.pushHighlight = () => {
      this.pushEventTo(this.liveComponent, 'highlight', this.params);
      this.highlighted = !this.highlighted;
    };

    this.el.addEventListener('mouseenter', () => {
      if (!this.highlighted) this.pushHighlight();
    });
    this.el.addEventListener('mouseleave', () => {
      if (this.highlighted) this.pushHighlight();
    });
  },
  destroyed() {
    this.el.removeEventListener('mouseenter', this.pushHighlight);
    this.el.removeEventListener('mouseleave', this.pushHighlight);

    setTimeout(() => {
      if (this.highlighted && this.liveComponent.checkVisibility()) {
        this.pushHighlight();
      }
    }, 200);
  },
};

export default Highlight;
