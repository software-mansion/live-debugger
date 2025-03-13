const Tooltip = {
  mounted() {
    this.handleMouseEnter = () => {
      tooltipEl.style.display = 'block';
      tooltipEl.innerHTML = this.el.dataset.tooltip;

      const tooltipRect = tooltipEl.getBoundingClientRect();
      const rect = this.el.getBoundingClientRect();

      const topOffset =
        this.el.dataset.position == 'top'
          ? rect.top - tooltipRect.height
          : rect.bottom;

      if (rect.left + tooltipRect.width > window.innerWidth) {
        tooltipEl.style.right = `${window.innerWidth - rect.right}px`;
        tooltipEl.style.left = 'auto';
      } else {
        tooltipEl.style.left = `${rect.left}px`;
        tooltipEl.style.right = 'auto';
      }

      tooltipEl.style.top = `${topOffset}px`;
      tooltipEl.style.zIndex = 100;
    };
    this.handleMouseLeave = () => {
      tooltipEl.style.display = 'none';
    };
    let tooltipEl = document.querySelector('#tooltip');
    tooltipEl.style.pointerEvents = 'none';
    this.el.addEventListener('mouseenter', this.handleMouseEnter);
    this.el.addEventListener('mouseleave', this.handleMouseLeave);
  },
  destroyed() {
    document.querySelector('#tooltip').style.display = 'none';
    this.el.removeEventListener('mouseenter', this.handleMouseEnter);
    this.el.removeEventListener('mouseleave', this.handleMouseLeave);
  },
};

export default Tooltip;
