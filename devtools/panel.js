const form = document.getElementById("pid_form");
const iframe = document.getElementById("content");
const socket_el = document.getElementById("socket_element");

function set_socket_id(socket_id) {
  iframe.src = `http://localhost:4000/live_debug/${socket_id}`;
}
