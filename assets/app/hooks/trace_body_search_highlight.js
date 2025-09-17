import { highlightSearchRanges } from '../utils/dom';

import { findRanges } from '../utils/dom';

const TraceBodySearchHighlight = {
  mounted() {
    const phrase = this.el.dataset.search_phrase;
    if (phrase === undefined || phrase === '') return;

    const ranges = findRanges(this.el, phrase);
    highlightSearchRanges(ranges);
  },
  updated() {
    const phrase = this.el.dataset.search_phrase;
    if (phrase === undefined || phrase === '') return;

    const ranges = findRanges(this.el, phrase);
    highlightSearchRanges(ranges);
  },
};

export default TraceBodySearchHighlight;
