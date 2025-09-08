export function setTooltipPosition(tooltipEl, referencedElement) {
  const tooltipRect = tooltipEl.getBoundingClientRect();
  const rect = referencedElement.getBoundingClientRect();

  // Reset any previous positioning
  tooltipEl.style.top = '';
  tooltipEl.style.left = '';
  tooltipEl.style.right = '';
  tooltipEl.style.bottom = '';
  tooltipEl.style.wordBreak = '';

  switch (referencedElement.dataset.position) {
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
    case 'top-center':
      tooltipEl.style.top = `${rect.top - tooltipRect.height - 5}px`;
      tooltipEl.style.left = `${rect.left + rect.width / 2 - tooltipRect.width / 2}px`;
      break;
  }

  // Handle horizontal overflow for top/bottom positions
  if (
    ['top', 'bottom', 'top-center'].includes(referencedElement.dataset.position)
  ) {
    if (tooltipRect.width > window.innerWidth) {
      tooltipEl.style.left = '10px';
      tooltipEl.style.right = '10px';
      tooltipEl.style.wordBreak = 'break-all';
    } else if (rect.left + tooltipRect.width > window.innerWidth) {
      tooltipEl.style.right = '10px';
      tooltipEl.style.left = 'auto';
    }
  }

  // Handle vertical overflow for left/right positions
  if (['left', 'right'].includes(referencedElement.dataset.position)) {
    if (rect.top + tooltipRect.height > window.innerHeight) {
      tooltipEl.style.top = `${window.innerHeight - tooltipRect.height}px`;
    }
  }

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
