function calculateInitialPosition(highlightRect, tooltipRect) {
  let top = highlightRect.top - tooltipRect.height - 10;
  let left = highlightRect.left;

  return { top, left };
}

function adjustVerticalPosition(
  top,
  highlightRect,
  tooltipRect,
  viewportHeight
) {
  // Check if tooltip would overflow top
  if (top < 10) {
    // Position below the highlight element
    top = highlightRect.bottom + 10;
  }

  // Check if tooltip would overflow bottom
  if (top + tooltipRect.height > viewportHeight - 10) {
    // Try to position above instead
    top = highlightRect.top - tooltipRect.height - 10;
    if (top < 10) {
      // If still overflowing, position at the top of viewport
      top = 10;
    }
  }

  // Ensure tooltip doesn't go off-screen vertically
  if (top < 10) top = 10;
  if (top + tooltipRect.height > viewportHeight - 10) {
    top = viewportHeight - tooltipRect.height - 10;
  }

  return top;
}

function adjustHorizontalPosition(left, tooltipRect, viewportWidth) {
  // Check if tooltip would overflow right
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  // Check if tooltip would overflow left
  if (left < 10) {
    left = 10;
  }

  // Ensure tooltip doesn't go off-screen horizontally
  if (left < 10) left = 10;
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }

  return left;
}

function applyPosition(tooltip, top, left) {
  tooltip.style.top = `${top + window.scrollY}px`;
  tooltip.style.left = `${left + window.scrollX}px`;
}

export function positionTooltip(tooltip, highlightElement) {
  if (!highlightElement || !tooltip) return;

  const highlightRect = highlightElement.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  let { top, left } = calculateInitialPosition(highlightRect, tooltipRect);

  top = adjustVerticalPosition(top, highlightRect, tooltipRect, viewportHeight);
  left = adjustHorizontalPosition(left, tooltipRect, viewportWidth);

  applyPosition(tooltip, top, left);

  return { top, left, tooltipRect };
}
