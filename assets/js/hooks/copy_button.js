import { setTooltipPosition } from './tooltip';

function fallbackCopyTextToClipboard(text) {
  const textArea = document.createElement('textarea');
  textArea.value = text;

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    document.execCommand('copy');
  } catch (err) {
    console.error('Fallback: unable to copy', err);
  }

  document.body.removeChild(textArea);
}

const CopyButton = {
  mounted() {
    const tooltipReferencedElement = this.el.closest('[phx-hook="Tooltip"]');
    const tooltipEl = document.getElementById('tooltip');

    this.el.addEventListener('click', () => {
      if (this.el.hasAttribute('in-iframe')) {
        // Due to permission issues inside devtools and lacking support of Clipboard API inside service workers
        // currently falling back to old api is the only way for copying to clipboard to work inside devtools
        fallbackCopyTextToClipboard(this.el.dataset.value);
      } else {
        navigator.clipboard.writeText(this.el.dataset.value);
      }

      tooltipEl.innerHTML = this.el.dataset.info;
      setTooltipPosition(tooltipEl, tooltipReferencedElement);
    });
  },
};

export default CopyButton;
