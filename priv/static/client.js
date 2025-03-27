(()=>{window.getLiveDebuggerURL=function(){return document.getElementById("live-debugger-scripts").src.replace("/assets/live_debugger/client.js","")};window.getSessionId=function(){return document.querySelector("[data-phx-main]").id};document.addEventListener("DOMContentLoaded",function(){let n=getLiveDebuggerURL(),d=getSessionId(),s=`
      <div id="debug-button" style="
        position: fixed;
        height: 40px;
        width: 40px;
        padding-left: 5px;
        padding-right: 5px;
        border-radius: 10px;
        background-color: #001A72;
        color: #ffffff;
        display: flex;
        gap: 5px;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        bottom: 20px;
        right: 20px;
        cursor: grab;">
        <a href="${n}/transport_pid/${d}" target="_blank">
          <svg viewBox="0 0 24 24" width="24" height="24"  fill="none" xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="evenodd" clip-rule="evenodd" d="M22.0941 20.624C22.5697 20.624 22.9553 20.2385 22.9554 19.7628L22.9556 16.6568C22.9556 16.4283 22.8649 16.2093 22.7034 16.0477C22.5418 15.8862 22.3228 15.7955 22.0944 15.7955L18.3034 15.7955L18.3034 17.5179L21.2331 17.5179L21.2329 19.7627C21.2329 20.2384 21.6185 20.624 22.0941 20.624Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M22.9823 12.9677C22.9823 12.4921 22.5968 12.1065 22.1211 12.1065L18.3034 12.1065V13.8289H22.1211C22.5968 13.8289 22.9823 13.4433 22.9823 12.9677Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M22.1385 5.31162C22.6142 5.31159 22.9998 5.69715 22.9998 6.17279L23 9.27886C23 9.50728 22.9093 9.72635 22.7478 9.88787C22.5863 10.0494 22.3672 10.1401 22.1388 10.1401L18.3034 10.1402L18.3164 8.41772L21.2775 8.4177L21.2774 6.1729C21.2773 5.69726 21.6629 5.31165 22.1385 5.31162Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M1.86148 20.624C1.38585 20.624 1.00024 20.2385 1.00021 19.7628L1 16.6568C0.999985 16.4283 1.09071 16.2093 1.25222 16.0478C1.41373 15.8862 1.6328 15.7955 1.86122 15.7955L5.6836 15.7955L5.6836 17.5179L2.7225 17.5179L2.72265 19.7627C2.72268 20.2384 2.33712 20.624 1.86148 20.624Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M1.00465 12.9677C1.00465 12.4921 1.39023 12.1065 1.86587 12.1065L5.6836 12.1065L5.68361 13.8289L1.86588 13.8289C1.39024 13.8289 1.00465 13.4434 1.00465 12.9677Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M1.8619 5.31162C1.38626 5.31159 1.00066 5.69715 1.00062 6.17279L1.00042 9.27886C1.00041 9.50728 1.09113 9.72635 1.25265 9.88787C1.41416 10.0494 1.63322 10.1401 1.86164 10.1401L5.68402 10.1402L5.68403 8.41773L2.72292 8.4177L2.72307 6.1729C2.7231 5.69726 2.33754 5.31165 1.8619 5.31162Z" fill="currentColor"/>
            <path fill-rule="evenodd" clip-rule="evenodd" d="M16.5822 5.951C16.5563 5.55988 16.4815 5.18216 16.3637 4.82389C15.761 2.9901 14.0347 1.66608 11.9993 1.66608C9.46255 1.66608 7.40614 3.72245 7.40607 6.25914C7.40607 6.07964 7.41637 5.90255 7.4364 5.72842C6.37344 6.4641 5.5006 7.27955 4.95972 7.82907C4.57693 8.21798 4.3604 8.47369 4.3604 8.47369V15.576C4.3604 16.9134 4.75938 18.2352 5.70216 19.1839C6.91489 20.4041 8.85964 21.9501 11.1606 22.2731C11.4426 22.3127 11.7299 22.3339 12.0219 22.3339C12.3121 22.3339 12.5995 22.3101 12.8831 22.266C15.0234 21.9325 16.9448 20.4369 18.1856 19.2336C19.1941 18.2556 19.6354 16.8718 19.6354 15.4671V8.47369C19.6354 8.47369 19.4208 8.21698 19.0408 7.8268C18.5007 7.27223 17.6266 6.44804 16.5597 5.7081C16.5693 5.78844 16.5768 5.86943 16.5822 5.951ZM9.94789 6.25926C9.21504 6.59448 8.48065 7.06772 7.79147 7.60478C7.27937 8.00384 6.83377 8.40537 6.483 8.74437L12.0205 12.0717L17.5232 8.74442C17.1757 8.40464 16.7328 8.00128 16.2228 7.60045C15.5416 7.06516 14.8151 6.59357 14.0886 6.25926H9.94789ZM11.9993 3.38852C13.0618 3.38852 13.9896 3.96582 14.4859 4.82389L9.51244 4.82411C10.0088 3.96592 10.9366 3.38852 11.9993 3.38852ZM11.1606 13.5645L6.08284 10.5134V15.576C6.08284 16.5949 6.38663 17.4291 6.92389 17.9697C8.02405 19.0767 9.53264 20.2139 11.1606 20.5272V13.5645ZM12.8831 20.5143C14.3643 20.1903 15.8444 19.1047 16.9865 17.9971C17.5787 17.4228 17.913 16.5336 17.913 15.4671V10.5216L12.8831 13.5629V20.5143Z" fill="currentColor"/>
          </svg>
        </a>
      </div>
  `,l=document.createElement("div");l.innerHTML=s;let e=l.firstElementChild;document.body.appendChild(e);let o=!1,u=t=>{t.button!==0||t.ctrlKey||(t.preventDefault(),posXStart=t.clientX,posYStart=t.clientY,document.addEventListener("mousemove",i),document.addEventListener("mouseup",r),e.style.cursor="grabbing",o=!1)},i=t=>{!t.clientX||!t.clientY||(o=!0,posX=posXStart-t.clientX,posY=posYStart-t.clientY,posXStart=t.clientX,posYStart=t.clientY,e.style.top=`${e.offsetTop-posY}px`,e.style.left=`${e.offsetLeft-posX}px`)},r=()=>{document.removeEventListener("mousemove",i),document.removeEventListener("mouseup",r),e.style.cursor="grab",e.offsetTop<0&&(e.style.top=e.style.bottom),e.offsetTop+e.clientHeight>window.innerHeight&&(e.style.top=""),e.offsetLeft<0&&(e.style.left=e.style.right),e.offsetLeft+e.clientWidth>window.innerWidth&&(e.style.left="")},c=t=>{o&&(t.preventDefault(),o=!1)};window.addEventListener("resize",()=>{e.offsetLeft+e.clientWidth+Number.parseInt(e.style.right)>window.innerWidth&&(e.style.left=""),e.offsetTop+e.clientHeight+Number.parseInt(e.style.bottom)>window.innerHeight&&(e.style.top="")}),e.addEventListener("mousedown",u),e.addEventListener("click",c),console.info(`LiveDebugger available at: ${n}`),console.log("test merge queue"),console.log("test merge queue #2"),console.log("test merge queue #3")});})();
