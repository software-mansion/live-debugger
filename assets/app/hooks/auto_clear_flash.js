// https://dev.to/brunoanken/automatically-clearing-flash-messages-in-phoenix-liveview-2g7n
const AutoClearFlash = {
  mounted() {
    let hideElementAfter = 5000; // ms
    let clearFlashAfter = hideElementAfter + 500; // ms

    setTimeout(() => {
      this.el.classList.add('max-sm:animate-fade-out-mobile');
      this.el.classList.add('sm:animate-fade-out');
    }, hideElementAfter);

    this.timeOutId = setTimeout(() => {
      this.pushEvent('lv:clear-flash');
    }, clearFlashAfter);
  },
  destroyed() {
    clearTimeout(this.timeOutId);
  },
};

export default AutoClearFlash;
