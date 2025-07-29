export function createDebugMenu() {
  const tooltipHtml = /*html*/ `
    <div id="debug-tooltip">
      <div class="tooltip-option" >
        Open in new tab
      </div>
      <div class="tooltip-option">
        Inspect elements
      </div>
      <div class="tooltip-option">
        Move button
      </div>
    </div>
  `;

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = tooltipHtml;
  const tooltip = tempDiv.firstElementChild;

  return tooltip;
}
