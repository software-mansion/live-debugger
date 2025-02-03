let Hooks = {};

Hooks.Tooltip = {
  mounted() {
    this.handleMouseEnter = () => {
      const rect = this.el.getBoundingClientRect();
      const topOffset = this.el.dataset.position === 'top' ? -45 : 0;

      tooltipEl.style.display = 'block';
      tooltipEl.style.top = `${rect.bottom + topOffset}px`;
      tooltipEl.style.left = `${rect.left}px`;
      tooltipEl.style.zIndex = 100;
      tooltipEl.innerHTML = this.el.dataset.tooltip;
    };
    this.handleMouseLeave = () => {
      tooltipEl.style.display = 'none';
    };
    let tooltipEl = document.querySelector('#tooltip');
    this.el.addEventListener('mouseenter', this.handleMouseEnter);
    this.el.addEventListener('mouseleave', this.handleMouseLeave);
  },
  destroyed() {
    document.querySelector('#tooltip').style.display = 'none';
    this.el.removeEventListener('mouseenter', this.handleMouseEnter);
    this.el.removeEventListener('mouseleave', this.handleMouseLeave);
  },
};

export default Hooks;
