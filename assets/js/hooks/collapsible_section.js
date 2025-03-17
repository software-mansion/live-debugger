import { screenSizes } from '../constants';

const CollapsibleSection = {
  mounted() {
    const collapsible = this.el.querySelector('details');

    this.disableCollapsible = (e) => {
      e.preventDefault();
    };
    this.handleResize = () => {
      if (window.innerWidth >= screenSizes.lg) {
        this.el.addEventListener('click', this.disableCollapsible);
        collapsible.open = true;
      } else {
        this.el.removeEventListener('click', this.disableCollapsible);
      }
    };
    window.addEventListener('resize', this.handleResize);
    this.handleResize();
  },
  destroyed() {
    window.removeEventListener('resize', this.handleResize);
    this.el.removeEventListener('click', this.disableCollapsible);
  },
};

export default CollapsibleSection;
