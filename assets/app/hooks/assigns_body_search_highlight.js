import { findRanges } from '../utils/dom';

let allRanges;

function highlightSearchRanges(allRanges) {
  if (allRanges.length === 0) {
    CSS.highlights.clear();
    return;
  }

  const highlight = new Highlight(...allRanges);
  CSS.highlights.set('search-highlight', highlight);
}

function handleHighlight(phrase) {
  if (phrase === undefined || phrase === '') {
    allRanges = [];
    CSS.highlights.clear();
    return;
  }

  allRanges = [];
  document
    .querySelectorAll('[phx-hook="AssignsBodySearchHighlight"]')
    .forEach((el) => {
      if (el.dataset.search_phrase === phrase) {
        const ranges = findRanges(el, phrase);
        allRanges.push(...ranges);
      }
    });

  highlightSearchRanges(allRanges);
}

const AssignsBodySearchHighlight = {
  mounted() {
    handleHighlight(this.el.dataset.search_phrase);
  },
  updated() {
    handleHighlight(this.el.dataset.search_phrase);
  },
};

export default AssignsBodySearchHighlight;
