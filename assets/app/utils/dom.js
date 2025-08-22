export function highlightSearchRanges(ranges) {
  let highlight = CSS.highlights.get('search-highlight');

  if (highlight) {
    const old_valid_ranges = highlight
      .values()
      .filter(({ collapsed }) => !collapsed);

    ranges = [...ranges, ...old_valid_ranges];
  }

  highlight = new Highlight(...ranges);
  CSS.highlights.set('search-highlight', highlight);
}
