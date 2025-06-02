function setOpen(el) {
  if (el.dataset.open === 'true') {
    el.open = true;
  } else {
    el.open = false;
  }
}

function handleCollapsibleEvent(payload, el) {
  if (payload.action === 'toggle') {
    el.open = !el.open;
  } else if (payload.action === 'open') {
    el.open = true;
  } else if (payload.action === 'close') {
    el.open = false;
  } else {
    console.warn(
      `Unknown action "${payload.action}" for collapsible with id "${el.id}"`
    );
  }
}

const Collapsible = {
  mounted() {
    setOpen(this.el);

    this.handleEvent(`${this.el.id}-collapsible`, (payload) => {
      handleCollapsibleEvent(payload, this.el);
    });
  },
};

export default Collapsible;
