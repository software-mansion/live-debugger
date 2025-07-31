import initDebugButton from './debug_button/debug_button';
import initDebugOptions from './debug_options/debug_options';

export default function initDebugMenu(liveDebuggerURL) {
  const debugButton = initDebugButton();
  const debugMenu = initDebugOptions({ liveDebuggerURL });

  document.body.appendChild(debugButton);
  document.body.appendChild(debugMenu);

  // Hide menu when clicking outside
  document.addEventListener('click', (event) => {
    if (
      !debugButton.contains(event.target) &&
      !debugMenu.contains(event.target)
    ) {
      const event = new CustomEvent('lvdbg:click-outside-debug-menu');
      document.dispatchEvent(event);
    }
  });

  return { debugButton, debugMenu };
}
