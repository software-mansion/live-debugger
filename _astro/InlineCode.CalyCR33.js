import{j as a,c as l}from"./utils.CP-DEBaU.js";import{r as n}from"./index.BGzeIQFi.js";import{B as f}from"./button.CK-PpVZ2.js";/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const y=t=>t.replace(/([a-z0-9])([A-Z])/g,"$1-$2").toLowerCase(),C=t=>t.replace(/^([A-Z])|[\s-_]+(\w)/g,(e,o,r)=>r?r.toUpperCase():o.toLowerCase()),m=t=>{const e=C(t);return e.charAt(0).toUpperCase()+e.slice(1)},p=(...t)=>t.filter((e,o,r)=>!!e&&e.trim()!==""&&r.indexOf(e)===o).join(" ").trim(),g=t=>{for(const e in t)if(e.startsWith("aria-")||e==="role"||e==="title")return!0};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var w={xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round"};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const b=n.forwardRef(({color:t="currentColor",size:e=24,strokeWidth:o=2,absoluteStrokeWidth:r,className:i="",children:s,iconNode:c,...d},u)=>n.createElement("svg",{ref:u,...w,width:e,height:e,stroke:t,strokeWidth:r?Number(o)*24/Number(e):o,className:p("lucide",i),...!s&&!g(d)&&{"aria-hidden":"true"},...d},[...c.map(([h,x])=>n.createElement(h,x)),...Array.isArray(s)?s:[s]]));/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const v=(t,e)=>{const o=n.forwardRef(({className:r,...i},s)=>n.createElement(b,{ref:s,iconNode:e,className:p(`lucide-${y(m(t))}`,`lucide-${t}`,r),...i}));return o.displayName=m(t),o};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const j=[["rect",{width:"14",height:"14",x:"8",y:"8",rx:"2",ry:"2",key:"17jyea"}],["path",{d:"M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2",key:"zix9uf"}]],N=v("copy",j);function B({codeString:t,...e}){const[o,r]=n.useState(!1),i=()=>{const s=document.createElement("textarea");s.value=t,document.body.appendChild(s),s.select();try{document.execCommand("copy"),r(!0),setTimeout(()=>r(!1),2e3)}catch(c){console.error("Failed to copy text: ",c)}document.body.removeChild(s)};return a.jsxs("div",{className:"group relative",children:[a.jsxs(f,{variant:"defaultWithOutline",className:l("absolute top-3 right-3 h-10 w-24","text-primary-foreground opacity-0 transition-opacity","group-hover:opacity-100","focus-visible:ring-ring focus-visible:opacity-100 focus-visible:ring-2"),onClick:i,children:[a.jsx("p",{className:"text-thin text-2xs",children:o?"Copied!":"Copy"}),!o&&a.jsx(N,{strokeWidth:2,className:"h-4 w-4"})]}),a.jsx("pre",{className:l("bg-swm-brand-80 min-h-35 overflow-x-auto p-6","text-primary-foreground text-sm",e.className),...e,children:a.jsx("p",{className:"font-lg font-secondary-strong font-normal",children:t})})]})}const k=n.forwardRef(({className:t,children:e,...o},r)=>a.jsx("code",{ref:r,className:l("inline-flex items-center align-baseline","rounded-md border border-slate-400","bg-swm-brand-80 mx-0.5 h-7 px-1.5","text-md text-primary-foreground font-normal",t),...o,children:e}));k.displayName="InlineCode";export{B as C,k as I};
