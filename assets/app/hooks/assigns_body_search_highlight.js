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
  const assignsFullscreenContainer = document.getElementById(
    'assigns-display-fullscreen-container'
  );
  const assignsContainer = document.getElementById('assigns-display-container');

  [assignsContainer, assignsFullscreenContainer].forEach((el) => {
    if (el && el.dataset.search_phrase === phrase) {
      const ranges = findRanges(el, phrase);
      allRanges.push(...ranges);
    }
  });

  highlightSearchRanges(allRanges);
}

const AssignsBodySearchHighlight = {
  mounted() {
    this.handleEvent('search_in_assigns', ({ search_phrase }) => {
      handleHighlight(search_phrase);
    });
  },
};

export default AssignsBodySearchHighlight;
