const IframeDetector = {
  mounted() {
    this.handleIframeDetection();
  },
  handleIframeDetection() {
    let inIframe = window.location !== window.parent.location;
    this.pushEventTo(this.el, 'detect-iframe', { 'in_iframe?': inIframe });
  },
};

export default IframeDetector;
