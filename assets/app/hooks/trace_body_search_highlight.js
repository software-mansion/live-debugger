import { highlightSearchRanges, findRanges } from '../utils/dom';

const rangesByElementId = new Map();

function updateGlobalHighlight() {
  const allRanges = Array.from(rangesByElementId.values()).flat();
  highlightSearchRanges('traces-search-highlight', allRanges, true);
}

const TraceBodySearchHighlight = {
  mounted() {
    this.handleHighlight();
  },

  updated() {
    this.handleHighlight();
  },

  destroyed() {
    rangesByElementId.delete(this.el.id);
    updateGlobalHighlight();
  },

  handleHighlight() {
    const phrase = this.el.dataset.search_phrase;

    if (!phrase) {
      rangesByElementId.delete(this.el.id);
    } else {
      rangesByElementId.set(this.el.id, findRanges(this.el, phrase));
    }

    updateGlobalHighlight();
  },
};

export default TraceBodySearchHighlight;
