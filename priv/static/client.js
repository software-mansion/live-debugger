// Fetch LiveDebugger URL
const URL = document
  .getElementById("live-debugger-js")
  .src.replace("/assets/client.js", "");

// Finalize
console.info(`LiveDebugger available at: ${URL}`);
