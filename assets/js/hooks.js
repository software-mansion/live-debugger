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

Hooks.Fullscreen = {
  mounted() {
    console.log(this.el.id);
    this.handleOpen = () => {
      console.log('open');
      this.el.showModal();
      this.el.classList.remove('hidden');
      this.el.classList.add('flex');
    };

    this.handleClose = () => {
      console.log('close');
      this.el.close();
      this.el.classList.remove('flex');
      this.el.classList.add('hidden');
    };

    this.el.addEventListener('open', this.handleOpen);
    this.el.addEventListener('close', this.handleClose);
  },
  destroyed() {
    this.el.removeEventListener('open', this.handleOpen);
    this.el.removeEventListener('close', this.handleClose);
  },
};

Hooks.CollapsibleOpen = {
  mounted() {
    this.el.open = true;
  },
};

export default Hooks;
