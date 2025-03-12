const ComponentsTree = {
  mounted() {
    const components = this.el.querySelectorAll('button');
    let params = {};

    components.forEach((el) => {
      el.addEventListener('mouseenter', (e) => {
        params = {
          search_attribute: e.target.dataset.search_attribute,
          search_value: e.target.dataset.search_value,
        };
        this.pushEvent('highlight', params);
      });
      el.addEventListener('mouseleave', (e) => {
        params = {
          search_attribute: e.target.dataset.search_attribute,
          search_value: e.target.dataset.search_value,
        };
        this.pushEvent('highlight', params);
      });
    });
  },
};

export default ComponentsTree;
