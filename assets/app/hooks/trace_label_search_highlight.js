import { highlightSearchRanges } from '../utils/dom';

function constructRanges(element, regexp) {
  const ranges = [];

  for (const match of element.textContent.matchAll(regexp)) {
    const range = new Range();
    range.setStart(element.firstChild, match.index);
    range.setEnd(element.firstChild, match.index + match[0].length);
    ranges.push(range);
  }

  return ranges;
}

function maybeShorten(text, maxLength = 150) {
  if (text.length > maxLength) {
    return text.slice(0, maxLength - 3) + '...';
  }
  return text;
}

function adjustTextContent(element, phrase) {
  match = element.textContent.match(new RegExp(RegExp.escape(phrase), 'i'));

  let shortened = element.textContent;

  if (match && match.index > 15) {
    shortened = '...' + shortened.slice(match.index - 12);
  }

  element.textContent = maybeShorten(shortened);
}

function handleHighlight(phrase, element) {
  if (phrase === undefined || phrase === '') {
    element.textContent = maybeShorten(element.textContent);
    return;
  }

  adjustTextContent(element, phrase);

  const phraseRegexp = new RegExp(RegExp.escape(phrase), 'gi');
  const traceContentRanges = constructRanges(element, phraseRegexp);

  highlightSearchRanges(traceContentRanges);
}

const TraceLabelSearchHighlight = {
  mounted() {
    handleHighlight(this.el.dataset.search_phrase, this.el);
  },
  updated() {
    console.log(this.el.dataset);
    handleHighlight(this.el.dataset.search_phrase, this.el);
  },
};

export default TraceLabelSearchHighlight;
