export default function initElementInspection() {
  console.log('Init element inspection');

  let inspectMode = false;

  const enableInspectMode = () => {
    if (inspectMode) {
      return;
    }

    inspectMode = true;
    console.log('Inspect mode enabled');
  };

  document.addEventListener('live-debugger-debug-button-inspect', (event) => {
    enableInspectMode();
  });
}
