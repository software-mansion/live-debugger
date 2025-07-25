export function createTooltipMenu() {
  const tooltipHtml = /*html*/ `
    <div id="debug-tooltip" style="
      position: absolute;
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
      min-width: 160px;
      z-index: 10000;
      display: none;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;">
      <div class="tooltip-option" style="
        padding: 8px 16px;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 8px;
        color: #374151;
        transition: background-color 0.15s;">
        Open in new tab
      </div>
      <div class="tooltip-option" style="
        padding: 8px 16px;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 8px;
        color: #374151;
        transition: background-color 0.15s;">
        Inspect mode
      </div>
      <div class="tooltip-option" style="
        padding: 8px 16px;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 8px;
        color: #374151;
        transition: background-color 0.15s;">
        Move
      </div>
    </div>
  `;

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = tooltipHtml;
  const tooltip = tempDiv.firstElementChild;

  // Add hover effects
  const options = tooltip.querySelectorAll('.tooltip-option');
  options.forEach((option) => {
    option.addEventListener('mouseenter', () => {
      option.style.backgroundColor = '#f3f4f6';
    });
    option.addEventListener('mouseleave', () => {
      option.style.backgroundColor = '';
    });
  });

  return tooltip;
}
