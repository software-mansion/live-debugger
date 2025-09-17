import { findRanges } from '../utils/dom';

function highlightSearchRanges(ranges) {
  highlight = new Highlight(...ranges);
  CSS.highlights.set('search-highlight', highlight);
}

function handleHighlight(phrase, root) {
  console.log(phrase);
  if (phrase === undefined || phrase === '') {
    CSS.highlights.clear();
    return;
  }

  const ranges = findRanges(root, phrase);
  highlightSearchRanges(ranges);
}

const AssignsBodySearchHighlight = {
  mounted() {
    handleHighlight(this.el.dataset.search_phrase, this.el);
  },
  updated() {
    if (!this.elementIsVisible()) return;
    handleHighlight(this.el.dataset.search_phrase, this.el);
  },

  elementIsVisible() {
    return !!(
      this.el.offsetParent !== null &&
      getComputedStyle(this.el).display !== 'none' &&
      getComputedStyle(this.el).visibility !== 'hidden'
    );
  },
};

export default AssignsBodySearchHighlight;
