const SearchPhraseHighlight = {
  mounted() {
    console.log('mounted: ', this.el.dataset.phrase);
  },
  updated() {
    console.log('updated: ', this.el.dataset.phrase);
    console.log(this.el);
  },
  destroyed() {
    console.log('destroyed: ', this.el.dataset.phrase);
  },
};

export default SearchPhraseHighlight;
