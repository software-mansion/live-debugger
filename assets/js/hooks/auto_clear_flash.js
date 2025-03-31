// https://dev.to/brunoanken/automatically-clearing-flash-messages-in-phoenix-liveview-2g7n
const AutoClearFlash = {
  mounted() {
    let ignoredIDs = ['client-error', 'server-error'];
    if (ignoredIDs.includes(this.el.id)) return;

    let hideElementAfter = 5000; // ms
    let clearFlashAfter = hideElementAfter + 500; // ms

    // first hide the element
    setTimeout(() => {
      this.el.style.opacity = 0;
    }, hideElementAfter);

    // then clear the flash
    setTimeout(() => {
      this.pushEvent('lv:clear-flash');
    }, clearFlashAfter);
  },
};

export default AutoClearFlash;
