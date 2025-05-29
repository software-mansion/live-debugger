export default function registerCollapsibleEvents() {
  window.addEventListener(
    'phx:collapsible',
    ({ detail: { id: id, action: action } }) => {
      const collapsible = document.getElementById(id);

      if (!collapsible) return;

      switch (action) {
        case 'toggle':
          collapsible.open = !collapsible.open;
          break;
        case 'open':
          collapsible.open = true;
          break;
        case 'close':
          collapsible.open = false;
          break;
        default:
          console.warn(
            `Unknown action "${action}" for collapsible with id "${id}"`
          );
          return;
      }
    }
  );
}
