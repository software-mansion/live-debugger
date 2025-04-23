const CollapsibleOpen = {
  mounted() {
    this.el.open = true;
  },
};

const CollapsibleChevronOnly = {
  mounted() {
    this.chevron = this.el.querySelector('.chevron');
    this.details = this.el.parentElement;
    this.handleClick = (e) => {
      if (e.target === this.chevron) {
        this.details.open = !this.details.open;
      }
      e.preventDefault();
    };

    this.el.addEventListener('click', this.handleClick);
  },
  destroyed() {
    this.el.removeEventListener('click', this.handleClick);
  },
};

export { CollapsibleOpen, CollapsibleChevronOnly };
