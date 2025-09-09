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

    this.handleStorage = (e) => {
      if (e.key !== 'theme') return;
      document.documentElement.classList.toggle('dark', e.newValue === 'dark');
    };

    window.addEventListener('storage', this.handleStorage);
  },

  destroyed() {
    this.el.removeEventListener('click', this.handleClick);
    window.removeEventListener('storage', this.handleStorage);
  },
};

export default ToggleTheme;
