export function setTooltipPosition(tooltipEl, referencedElement) {
  const tooltipRect = tooltipEl.getBoundingClientRect();
  const rect = referencedElement.getBoundingClientRect();

  const topOffset =
    referencedElement.dataset.position == 'top'
      ? rect.top - tooltipRect.height
      : rect.bottom;

  if (rect.left + tooltipRect.width > window.innerWidth) {
    tooltipEl.style.right = `${window.innerWidth - rect.right}px`;
    tooltipEl.style.left = 'auto';
  } else {
    tooltipEl.style.left = `${rect.left + rect.width / 2 - tooltipRect.width / 2}px`;
    tooltipEl.style.right = 'auto';
  }

  tooltipEl.style.top = `${topOffset}px`;
  tooltipEl.style.zIndex = 100;
}

const Tooltip = {
  mounted() {
    const tooltipEl = document.querySelector('#tooltip');
    tooltipEl.style.pointerEvents = 'none';

    this.handleMouseEnter = () => {
      tooltipEl.style.display = 'block';
      tooltipEl.innerHTML = this.el.dataset.tooltip;
      setTooltipPosition(tooltipEl, this.el);
    };
    this.handleMouseLeave = () => {
      tooltipEl.style.display = 'none';
    };

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
