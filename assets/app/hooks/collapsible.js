function setOpen(el) {
  if (el.dataset.saveStateInBrowser === 'true') {
    setOpenFromLocalStorage(el);
    return;
  }

  if (el.dataset.open === 'true') {
    el.open = true;
  } else {
    el.open = false;
  }
}

function setOpenFromLocalStorage(el) {
  const open_state = localStorage.getItem(`lvdbg:collapsible-open-${el.id}`);

  if (open_state !== null) {
    el.open = open_state === 'true';
    return;
  }

  if (el.dataset.open === 'true') {
    el.open = true;
    localStorage.setItem(`lvdbg:collapsible-open-${el.id}`, 'true');
  } else {
    el.open = false;
    localStorage.setItem(`lvdbg:collapsible-open-${el.id}`, 'false');
  }
}

function maybeSaveStateOnChange(el) {
  if (el.dataset.saveStateInBrowser === 'true') {
    el.addEventListener('toggle', () => {
      localStorage.setItem(
        `lvdbg:collapsible-open-${el.id}`,
        el.open.toString()
      );
    });

    window.addEventListener('storage', ({ key }) => {
      if (key !== `lvdbg:collapsible-open-${el.id}`) return;
      setOpenFromLocalStorage(el);
    });
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
    console.error(
      `Unknown action "${payload.action}" for collapsible with id "${el.id}"`
    );
  }
}

const Collapsible = {
  mounted() {
    setOpen(this.el);

    maybeSaveStateOnChange(this.el);

    this.handleEvent(`${this.el.id}-collapsible`, (payload) => {
      handleCollapsibleEvent(payload, this.el);
    });
  },
};

export default Collapsible;
