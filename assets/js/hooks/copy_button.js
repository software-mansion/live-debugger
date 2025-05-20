const CopyButton = {
  mounted() {
    this.el.addEventListener('click', () => {
      navigator.clipboard.writeText(detail.value);
      document.getElementById('tooltip').innerHTML = this.el.dataset.info;
    });
  },
};

export default CopyButton;
