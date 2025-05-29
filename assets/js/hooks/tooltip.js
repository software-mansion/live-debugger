const Tooltip = {
  mounted() {
    this.handleMouseEnter = () => {
      tooltipEl.style.display = 'block';
      tooltipEl.classList.add(`tooltip-${this.el.dataset.variant}`);
      tooltipEl.innerHTML = this.el.dataset.tooltip;

      const tooltipRect = tooltipEl.getBoundingClientRect();
      const rect = this.el.getBoundingClientRect();

      // Reset any previous positioning
      tooltipEl.style.top = '';
      tooltipEl.style.left = '';
      tooltipEl.style.right = '';
      tooltipEl.style.bottom = '';

      switch (this.el.dataset.position) {
        case 'top':
          tooltipEl.style.top = `${rect.top - tooltipRect.height}px`;
          tooltipEl.style.left = `${rect.left}px`;
          break;
        case 'bottom':
          tooltipEl.style.top = `${rect.bottom}px`;
          tooltipEl.style.left = `${rect.left}px`;
          break;
        case 'left':
          tooltipEl.style.left = `${rect.left - tooltipRect.width}px`;
          tooltipEl.style.top = `${rect.top + (rect.height - tooltipRect.height) / 2}px`;
          break;
        case 'right':
          tooltipEl.style.left = `${rect.right}px`;
          tooltipEl.style.top = `${rect.top + (rect.height - tooltipRect.height) / 2}px`;
          break;
      }

      // Handle horizontal overflow for top/bottom positions
      if (['top', 'bottom'].includes(this.el.dataset.position)) {
        if (rect.left + tooltipRect.width > window.innerWidth) {
          tooltipEl.style.right = `${window.innerWidth - rect.right}px`;
          tooltipEl.style.left = 'auto';
        }
      }

      // Handle vertical overflow for left/right positions
      if (['left', 'right'].includes(this.el.dataset.position)) {
        if (rect.top + tooltipRect.height > window.innerHeight) {
          tooltipEl.style.top = `${window.innerHeight - tooltipRect.height}px`;
        }
      }

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
