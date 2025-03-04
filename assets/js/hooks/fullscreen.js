const Fullscreen = {
  mounted() {
    this.handleOpen = () => {
      this.el.showModal();
      this.el.classList.remove('hidden');
      this.el.classList.add('flex');
    };

    this.handleClose = () => {
      this.el.close();
      this.el.classList.remove('flex');
      this.el.classList.add('hidden');
    };

    // Events from the browser
    this.el.addEventListener(`${this.el.id}-open`, this.handleOpen);
    this.el.addEventListener(`${this.el.id}-close`, this.handleClose);

    // Events from the server
    this.handleEvent(`${this.el.id}-open`, this.handleOpen);
    this.handleEvent(`${this.el.id}-close`, this.handleClose);
  },
  destroyed() {
    this.el.removeEventListener(`${this.el.id}-open`, this.handleOpen);
    this.el.removeEventListener(`${this.el.id}-close`, this.handleClose);
  },
};

export default Fullscreen;
