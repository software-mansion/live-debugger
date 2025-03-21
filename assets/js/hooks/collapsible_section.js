import { screenSizes } from '../constants';

const CollapsibleSection = {
  mounted() {
    const collapsible = this.el.querySelector('details');
    const label = this.el.querySelector('summary');

    this.disableCollapsible = (e) => {
      e.preventDefault();
    };
    this.handleResize = () => {
      if (window.innerWidth >= screenSizes.lg) {
        this.el.addEventListener('click', this.disableCollapsible);
        collapsible.open = true;
        label.tabIndex = -1;
      } else {
        this.el.removeEventListener('click', this.disableCollapsible);
        label.tabIndex = 0;
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
