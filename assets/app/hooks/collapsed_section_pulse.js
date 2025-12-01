const CollapsedSectionPulse = {
  mounted() {
    const collapsibleEl = this.el.closest('details');

    this.handleEvent(`${this.el.id}-pulse`, () => {
      if (collapsibleEl.open) return;

      collapsibleEl.classList.add('animate-section-pulse');

      setTimeout(() => {
        collapsibleEl.classList.remove('animate-section-pulse');
      }, 500);
    });
  },
};

export default CollapsedSectionPulse;
