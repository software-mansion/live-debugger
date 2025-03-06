const iframe = document.getElementById("content");

function set_iframe_url(url) {
  if (url) {
    iframe.src = url;
  } else {
    iframe.hidden = true;
    const errorInfo = document.getElementById("error-info");
    errorInfo.hidden = false;
    errorInfo.style.display = "flex";
  }
}
