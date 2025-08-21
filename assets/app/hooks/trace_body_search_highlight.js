import { highlightSearchRanges } from '../utils/dom';

function findRanges(root, search) {
  let text = '';
  const parts = [];
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);

  while (walker.nextNode()) {
    const node = walker.currentNode;

    if (node.parentElement.dataset.text_item === 'true') {
      const start = text.length;
      text += node.nodeValue;
      const end = text.length;
      parts.push({ node, start, end });
    }
  }

  const searchRegexp = new RegExp(RegExp.escape(search), 'gi');
  const ranges = [];

  for (const match of text.matchAll(searchRegexp)) {
    const matchStart = match.index;
    const matchEnd = matchStart + search.length;

    for (const { node, start, end } of parts) {
      if (end <= matchStart) continue;
      if (start >= matchEnd) break;

      let d = node.parentElement.closest('details');
      while (d) {
        d.dataset.open = true;
        d = d.parentElement.closest('details');
      }

      const range = document.createRange();
      range.setStart(node, Math.max(0, matchStart - start));
      range.setEnd(node, Math.min(node.nodeValue.length, matchEnd - start));
      ranges.push(range);
    }
  }

  return ranges;
}

const TraceBodySearchHighlight = {
  mounted() {
    const phrase = this.el.dataset.search_phrase;
    if (phrase === undefined || phrase === '') return;

    const ranges = findRanges(this.el, phrase);

    highlightSearchRanges(ranges);
  },
};

export default TraceBodySearchHighlight;
