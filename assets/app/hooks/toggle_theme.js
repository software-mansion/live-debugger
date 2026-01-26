const ToggleTheme = {
  mounted() {
    this.handleClick = () => {
      switch (localStorage.getItem('lvdbg:theme')) {
        case 'light':
          document.documentElement.classList.add('dark');
          localStorage.setItem('lvdbg:theme', 'dark');
          break;
        case 'dark':
          document.documentElement.classList.remove('dark');
          localStorage.setItem('lvdbg:theme', 'light');
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
