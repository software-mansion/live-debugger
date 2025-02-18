let Hooks = {};

Hooks.Tooltip = {
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
    this.el.addEventListener('mouseenter', this.handleMouseEnter);
    this.el.addEventListener('mouseleave', this.handleMouseLeave);
  },
  destroyed() {
    document.querySelector('#tooltip').style.display = 'none';
    this.el.removeEventListener('mouseenter', this.handleMouseEnter);
    this.el.removeEventListener('mouseleave', this.handleMouseLeave);
  },
};

Hooks.OpenFullscreen = {
  mounted() {
    const fullscreenId = this.el.dataset.fullscreenId;
    let fullscreen = document.querySelector(`#${fullscreenId}`);
    this.handleOpen = () => {
      fullscreen.showModal();
      fullscreen.classList.remove('hidden');
      fullscreen.classList.add('flex');
    };
    this.el.addEventListener('click', this.handleOpen);
  },
  destroyed() {
    this.el.removeEventListener('click', this.handleOpen);
  },
};

Hooks.CloseFullscreen = {
  mounted() {
    const fullscreenId = this.el.dataset.fullscreenId;
    let fullscreen = document.querySelector(`#${fullscreenId}`);
    this.handleClose = () => {
      fullscreen.close();
    };
    this.el.addEventListener('click', this.handleClose);
  },
  destroyed() {
    this.el.removeEventListener('click', this.handleClose);
  },
};

Hooks.Fullscreen = {
  mounted() {
    let fullscreen = this.el;
    this.handleClosed = () => {
      fullscreen.classList.remove('flex');
      fullscreen.classList.add('hidden');
    };
    fullscreen.addEventListener('close', this.handleClosed);
  },
  destroyed() {
    this.el.removeEventListener('close', this.handleClosed);
  },
};

Hooks.CollapsibleOpen = {
  mounted() {
    this.el.open = true;
  },
};

export default Hooks;
