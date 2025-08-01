const ToggleTheme = {
  mounted() {
    this.handleClick = () => {
      switch (localStorage.theme) {
        case 'light':
          document.documentElement.classList.add('dark');
          localStorage.theme = 'dark';
          break;
        case 'dark':
          document.documentElement.classList.remove('dark');
          localStorage.theme = 'light';
          break;
        default:
          break;
      }
    };

    this.el.addEventListener('click', this.handleClick);
  },

  destroyed() {
    this.el.removeEventListener('click', this.handleClick);
  },
};

export default ToggleTheme;
