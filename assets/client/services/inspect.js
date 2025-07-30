export default function initElementInspection() {
  console.log('Init element inspection');

  let inspectMode = false;

  const handleInspect = () => {
    console.log('Inspecting...');
    disableInspectMode();
  };

  const disableInspectMode = () => {
    if (!inspectMode) {
      return;
    }

    inspectMode = false;
    document.body.style.cursor = 'default';
    window.removeEventListener('click', handleInspect);
  };

  const enableInspectMode = () => {
    if (inspectMode) {
      return;
    }

    inspectMode = true;
    document.body.style.cursor = 'crosshair';
    window.addEventListener('click', handleInspect);
    console.log('Inspect mode enabled');
  };

  document.addEventListener('live-debugger-debug-button-inspect', (event) => {
    setTimeout(enableInspectMode);
  });
}
