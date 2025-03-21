(()=>{var d=document.getElementById("live-debugger-scripts").src.replace("/assets/client.js","");document.addEventListener("DOMContentLoaded",function(){let r=document.querySelector("[data-phx-main]").id,l=`
      <div id="debug-button" style="
        position: fixed;
        height: 40px;
        width: 40px;
        padding-left: 5px;
        padding-right: 5px;
        border-radius: 10px;
        background-color: #001A72;
        display: flex;
        gap: 5px;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        bottom: 20px;
        right: 20px;
        cursor: grab;">
        <a href="${d}/transport_pid/${r}" target="_blank">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-bug"><path d="m8 2 1.88 1.88"/><path d="M14.12 3.88 16 2"/><path d="M9 7.13v-1a3.003 3.003 0 1 1 6 0v1"/><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6"/><path d="M12 20v-9"/><path d="M6.53 9C4.6 8.8 3 7.1 3 5"/><path d="M6 13H2"/><path d="M3 21c0-2.1 1.7-3.9 3.8-4"/><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4"/><path d="M22 13h-4"/><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4"/></svg>
        </a>
      </div>
  `,n=document.createElement("div");n.innerHTML=l;let t=n.firstElementChild;document.body.appendChild(t);let o=!1,a=e=>{e.button!==0||e.ctrlKey||(e.preventDefault(),posXStart=e.clientX,posYStart=e.clientY,document.addEventListener("mousemove",i),document.addEventListener("mouseup",s),t.style.cursor="grabbing",o=!1)},i=e=>{!e.clientX||!e.clientY||(o=!0,posX=posXStart-e.clientX,posY=posYStart-e.clientY,posXStart=e.clientX,posYStart=e.clientY,t.style.top=`${t.offsetTop-posY}px`,t.style.left=`${t.offsetLeft-posX}px`)},s=()=>{document.removeEventListener("mousemove",i),document.removeEventListener("mouseup",s),t.style.cursor="grab",t.offsetTop<0&&(t.style.top=t.style.bottom),t.offsetTop+t.clientHeight>window.innerHeight&&(t.style.top=""),t.offsetLeft<0&&(t.style.left=t.style.right),t.offsetLeft+t.clientWidth>window.innerWidth&&(t.style.left="")},p=e=>{o&&(e.preventDefault(),o=!1)};window.addEventListener("resize",()=>{t.offsetLeft+t.clientWidth+Number.parseInt(t.style.right)>window.innerWidth&&(t.style.left=""),t.offsetTop+t.clientHeight+Number.parseInt(t.style.bottom)>window.innerHeight&&(t.style.top="")}),t.addEventListener("mousedown",a),t.addEventListener("click",p)});console.info(`LiveDebugger available at: ${d}`);})();
