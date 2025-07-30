export default function initElementInspection() {
  console.log('Init element inspection');

  let inspectMode = false;

  const handleInspect = (event) => {
    event.stopPropagation();
    console.log('Inspecting...');
    disableInspectMode();
  };

  const disableInspectMode = () => {
    if (!inspectMode) {
      return;
    }

    inspectMode = false;
    document.body.classList.remove('force-cursor-crosshair');
    document.body.removeEventListener('click', handleInspect);
  };

  const enableInspectMode = () => {
    if (inspectMode) {
      return;
    }

    inspectMode = true;
    document.body.classList.add('force-cursor-crosshair');
    document.body.addEventListener('click', handleInspect);
    console.log('Inspect mode enabled');
  };

  document.addEventListener('live-debugger-debug-button-inspect', (event) => {
    setTimeout(enableInspectMode);
  });
}
