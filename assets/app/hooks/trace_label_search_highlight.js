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

function adjustShortTraceContent(element, phrase) {
  match = element.textContent.match(new RegExp(RegExp.escape(phrase), 'i'));

  let shortened = element.textContent;

  if (match && match.index > 15) {
    shortened = '...' + shortened.slice(match.index - 12);
  }

  element.textContent = maybeShorten(shortened);
}

function handleHighlight(phrase, callbackNameEl, traceContentEl) {
  if (phrase === undefined || phrase === '') {
    traceContentEl.textContent = maybeShorten(traceContentEl.textContent);
    return;
  }

  adjustShortTraceContent(traceContentEl, phrase);

  const phraseRegexp = new RegExp(RegExp.escape(phrase), 'gi');
  const callbackNameRanges = constructRanges(callbackNameEl, phraseRegexp);
  const traceContentRanges = constructRanges(traceContentEl, phraseRegexp);

  highlightSearchRanges(...callbackNameRanges, ...traceContentRanges);
}

const TraceLabelSearchHighlight = {
  mounted() {
    const phrase = this.el.dataset.phrase;
    const traceContentEl = this.el.querySelector('.short-trace-content');
    const callbackNameEl = this.el.querySelector('.callback-name');

    if (phrase === undefined || phrase === '') {
      traceContentEl.textContent = maybeShorten(traceContentEl.textContent);
      return;
    }

    adjustShortTraceContent(traceContentEl, phrase);

    const phraseRegexp = new RegExp(RegExp.escape(phrase), 'gi');
    const callbackNameRanges = constructRanges(callbackNameEl, phraseRegexp);
    const traceContentRanges = constructRanges(traceContentEl, phraseRegexp);

    highlightSearchRanges(...callbackNameRanges, ...traceContentRanges);
  },
  updated() {
    const phrase = this.el.dataset.phrase;
    const traceContentEl = this.el.querySelector('.short-trace-content');
    const callbackNameEl = this.el.querySelector('.callback-name');

    handleHighlight(phrase, callbackNameEl, traceContentEl);
  },
};

export default TraceLabelSearchHighlight;
