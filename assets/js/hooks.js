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

Hooks.OpenFullscreen = {
  mounted() {
    const fullscreenId = this.el.dataset.fullscreenId;
    let fullscreen = document.querySelector(`#${fullscreenId}`);
    this.el.addEventListener('click', () => {
      fullscreen.showFullscreen();
      fullscreen.classList.remove('hidden');
      fullscreen.classList.add('flex');
    });
  },
  destroyed() {
    this.el.removeEventListener('click');
  },
};

Hooks.CloseFullscreen = {
  mounted() {
    const fullscreenId = this.el.dataset.fullscreenId;
    let fullscreen = document.querySelector(`#${fullscreenId}`);
    this.el.addEventListener('click', () => {
      fullscreen.close();
    });
  },
  destroyed() {
    this.el.removeEventListener('click');
  },
};

Hooks.Fullscreen = {
  mounted() {
    let fullscreen = this.el;
    fullscreen.addEventListener('close', (_e) => {
      fullscreen.classList.remove('flex');
      fullscreen.classList.add('hidden');
    });
  },
  destroyed() {
    this.el.removeEventListener('close');
  },
};

export default Hooks;
