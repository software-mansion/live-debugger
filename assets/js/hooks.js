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

Hooks.OpenModal = {
  mounted() {
    const modalId = this.el.dataset.modalId;
    let modal = document.querySelector(`#${modalId}`);
    this.el.addEventListener('click', () => {
      modal.showModal();
      modal.classList.remove('hidden');
      modal.classList.add('flex');
    });
  },
  destroyed() {
    this.el.removeEventListener('click');
  },
};

Hooks.CloseModal = {
  mounted() {
    const modalId = this.el.dataset.modalId;
    let modal = document.querySelector(`#${modalId}`);
    this.el.addEventListener('click', () => {
      modal.close();
    });
  },
  destroyed() {
    this.el.removeEventListener('click');
  },
};

Hooks.Modal = {
  mounted() {
    let modal = this.el;
    modal.addEventListener('close', (_e) => {
      modal.classList.remove('flex');
      modal.classList.add('hidden');
    });
  },
  destroyed() {
    this.el.removeEventListener('close');
  },
};

export default Hooks;
