import { findRanges } from '../utils/dom';

function highlightSearchRanges(allRanges) {
  if (allRanges.length === 0) {
    CSS.highlights.clear();
    return;
  }

  const highlight = new Highlight(...allRanges);
  CSS.highlights.set('search-highlight', highlight);
}

function handleHighlight() {
  const allRanges = [];
  const assignsFullscreenContainer = document.getElementById(
    'assigns-display-fullscreen-container'
  );
  const assignsContainer = document.getElementById('assigns-display-container');

  [assignsContainer, assignsFullscreenContainer].forEach((el) => {
    const phrase = el.dataset.search_phrase;
    if (el && phrase && phrase !== '') {
      const ranges = findRanges(el, phrase);
      allRanges.push(...ranges);
    }
  });

  highlightSearchRanges(allRanges);
}

const AssignsBodySearchHighlight = {
  mounted() {
    handleHighlight();
  },
  updated() {
    handleHighlight();
  },
};

export default AssignsBodySearchHighlight;
