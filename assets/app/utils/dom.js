export function highlightSearchRanges(highlightName, ranges, reset = false) {
  let highlight = CSS.highlights.get(highlightName);

  if (highlight && !reset) {
    const old_valid_ranges = highlight
      .values()
      .filter(({ collapsed }) => !collapsed);

    ranges = [...ranges, ...old_valid_ranges];
  }

  highlight = new Highlight(...ranges);
  CSS.highlights.set(highlightName, highlight);
}

export function findRanges(root, search) {
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

      let collapsibleElement = node.parentElement.closest('details');
      while (collapsibleElement) {
        collapsibleElement.dataset.open = true;
        collapsibleElement.open = true;
        collapsibleElement =
          collapsibleElement.parentElement.closest('details');
      }

      const range = document.createRange();
      range.setStart(node, Math.max(0, matchStart - start));
      range.setEnd(node, Math.min(node.nodeValue.length, matchEnd - start));
      ranges.push(range);
    }
  }

  return ranges;
}
