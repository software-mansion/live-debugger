import { setTooltipPosition } from './tooltip';

const CopyButton = {
  mounted() {
    const tooltipReferencedElement = this.el.closest('[phx-hook="Tooltip"]');
    const tooltipEl = document.getElementById('tooltip');

    this.el.addEventListener('click', () => {
      navigator.clipboard.writeText(this.el.dataset.value);

      tooltipEl.innerHTML = this.el.dataset.info;
      setTooltipPosition(tooltipEl, tooltipReferencedElement);
    });
  },
};

export default CopyButton;
