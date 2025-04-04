// https://dev.to/brunoanken/automatically-clearing-flash-messages-in-phoenix-liveview-2g7n
const AutoClearFlash = {
  mounted() {
    let hideElementAfter = 4000; // ms
    let clearFlashAfter = hideElementAfter + 500; // ms

    // first hide the element
    setTimeout(() => {
      this.el.classList.add('max-sm:animate-fadeOutMobile');
      this.el.classList.add('sm:animate-fadeOut');
    }, hideElementAfter);

    // then clear the flash
    this.timeOutId = setTimeout(() => {
      this.pushEvent('lv:clear-flash');
    }, clearFlashAfter);
  },
  destroyed() {
    // clear the timeout if the element is destroyed before the timeout is reached
    clearTimeout(this.timeOutId);
  },
};

export default AutoClearFlash;
