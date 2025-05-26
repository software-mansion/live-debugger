const iframe = document.getElementById("content");
const errorInfo = document.getElementById("error-info");

function setIframeUrl(url) {
  if (url) {
    iframe.src = url;
    iframe.hidden = false;
    errorInfo.hidden = true;
    errorInfo.style.display = "none";
  } else {
    iframe.hidden = true;
    errorInfo.hidden = false;
    errorInfo.style.display = "flex";
  }
}
