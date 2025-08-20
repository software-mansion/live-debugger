export function highlightSearchRanges(ranges) {
  let highlight = CSS.highlights.get('search-highlight');

  if (highlight) {
    ranges = [...ranges, ...highlight.values()];
  }

  highlight = new Highlight(...ranges);
  CSS.highlights.set('search-highlight', highlight);
}
