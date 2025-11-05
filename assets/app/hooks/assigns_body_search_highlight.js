import { findRanges, highlightSearchRanges } from '../utils/dom';

function handleHighlight() {
  const allRanges = [];
  const assignsFullscreenContainer = document.getElementById(
    'assigns-display-fullscreen-container'
  );
  const assignsContainer = document.getElementById('assigns-display-container');

  [assignsContainer, assignsFullscreenContainer].forEach((el) => {
    if (!el) return;
    const phrase = el.dataset.search_phrase;
    if (phrase && phrase !== '') {
      const ranges = findRanges(el, phrase);
      allRanges.push(...ranges);
    }
  });

  highlightSearchRanges('assigns-search-highlight', allRanges, true);
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
