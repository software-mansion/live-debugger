function setOpen(el) {
  if (el.dataset.open === 'true') {
    el.open = true;
  } else {
    el.open = false;
  }
}

function handleCollapsibleEvent(payload, el, cache) {
  if (payload.action === 'toggle') {
    el.open = !el.open;
  } else if (payload.action === 'open') {
    el.open = true;
    addChildren(el, cache);
  } else if (payload.action === 'close') {
    el.open = false;
    cache = getChildrenWithoutSummary(el);
    removeChildren(el, cache);
  } else {
    console.error(
      `Unknown action "${payload.action}" for collapsible with id "${el.id}"`
    );
  }
}

function getChildrenWithoutSummary(el) {
  return [...el.childNodes].filter((child) => child.tagName !== 'SUMMARY');
}

function removeChildren(el, children) {
  for (child of children) {
    el.removeChild(child);
  }
}

function addChildren(el, children) {
  for (child of children) {
    el.appendChild(child);
  }
}

const Collapsible = {
  mounted() {
    let cachedChildNodes = getChildrenWithoutSummary(this.el);

    handleCacheToggle = ({ target, newState }) => {
      if (newState === 'closed') {
        cachedChildNodes = getChildrenWithoutSummary(target);
        removeChildren(target, cachedChildNodes);
      }
      if (newState === 'open') {
        addChildren(target, cachedChildNodes);
      }
    };

    setOpen(this.el);

    if (!this.el.open) {
      removeChildren(this.el, cachedChildNodes);
    }

    this.el.addEventListener('toggle', handleCacheToggle);

    this.handleEvent(`${this.el.id}-collapsible`, (payload) => {
      handleCollapsibleEvent(payload, this.el, cachedChildNodes);
    });
  },
  destroyed() {
    this.el.removeEventListener('toggle', handleCacheToggle);
  },
};

export default Collapsible;
