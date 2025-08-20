import { highlightSearchRanges } from '../utils/dom';

function findRanges(root, search) {
  const ranges = [];
  let text = '';
  const parts = [];

  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const node = walker.currentNode;
    if (node.parentElement.classList.contains('whitespace-pre')) {
      const start = text.length;
      text += node.nodeValue;
      const end = text.length;
      parts.push({ node, start, end });
    }
  }

  const matches = text.matchAll(new RegExp(RegExp.escape(search), 'gi'));

  for (const match of matches) {
    const matchStart = match.index;
    const matchEnd = matchStart + search.length;

    for (const { node, start, end } of parts) {
      if (end <= matchStart) continue;
      if (start >= matchEnd) break;

      let d = node.parentElement.closest('details');
      while (d.dataset.open === 'false') {
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
    const phrase = this.el.dataset.phrase;
    if (phrase === undefined || phrase === '') return;

    const ranges = findRanges(this.el, phrase);

    highlightSearchRanges(...ranges);
  },
};

export default TraceBodySearchHighlight;
