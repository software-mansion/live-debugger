import{j as n,c as l}from"./utils.CP-DEBaU.js";import{r as i}from"./index.BGzeIQFi.js";import{B as f}from"./button.Cv4HPvev.js";/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const y=t=>t.replace(/([a-z0-9])([A-Z])/g,"$1-$2").toLowerCase(),C=t=>t.replace(/^([A-Z])|[\s-_]+(\w)/g,(e,o,r)=>r?r.toUpperCase():o.toLowerCase()),m=t=>{const e=C(t);return e.charAt(0).toUpperCase()+e.slice(1)},d=(...t)=>t.filter((e,o,r)=>!!e&&e.trim()!==""&&r.indexOf(e)===o).join(" ").trim(),b=t=>{for(const e in t)if(e.startsWith("aria-")||e==="role"||e==="title")return!0};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var g={xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round"};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const w=i.forwardRef(({color:t="currentColor",size:e=24,strokeWidth:o=2,absoluteStrokeWidth:r,className:a="",children:s,iconNode:p,...c},u)=>i.createElement("svg",{ref:u,...g,width:e,height:e,stroke:t,strokeWidth:r?Number(o)*24/Number(e):o,className:d("lucide",a),...!s&&!b(c)&&{"aria-hidden":"true"},...c},[...p.map(([x,h])=>i.createElement(x,h)),...Array.isArray(s)?s:[s]]));/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const v=(t,e)=>{const o=i.forwardRef(({className:r,...a},s)=>i.createElement(w,{ref:s,iconNode:e,className:d(`lucide-${y(m(t))}`,`lucide-${t}`,r),...a}));return o.displayName=m(t),o};/**
 * @license lucide-react v0.546.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const j=[["rect",{width:"14",height:"14",x:"8",y:"8",rx:"2",ry:"2",key:"17jyea"}],["path",{d:"M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2",key:"zix9uf"}]],k=v("copy",j);function I({codeString:t}){const[e,o]=i.useState(!1),r=()=>{const a=document.createElement("textarea");a.value=t,document.body.appendChild(a),a.select();try{document.execCommand("copy"),o(!0),setTimeout(()=>o(!1),2e3)}catch(s){console.error("Failed to copy text: ",s)}document.body.removeChild(a)};return n.jsxs("div",{className:"group relative",children:[n.jsx(f,{variant:"defaultWithOutline",size:"xs",className:l("max-sm:left-1/2 max-sm:-translate-x-1/2","absolute bottom-5","sm:right-4 md:top-4 md:bottom-auto","text-primary-foreground opacity-0 transition-opacity max-sm:opacity-100","group-hover:opacity-100","focus-visible:ring-ring focus-visible:opacity-100 focus-visible:ring-2"),onClick:r,children:n.jsxs("div",{className:"flex items-center gap-2.5 px-2 align-middle",children:[n.jsx("p",{className:"text-medium text-md",children:e?"Copied!":"Copy"}),!e&&n.jsx(k,{strokeWidth:2,className:"h-4 w-4 md:h-5 md:w-5"})]})}),n.jsx("div",{className:"bg-swm-brand-80 min-h-35 overflow-x-auto p-6 max-md:pb-18 max-sm:pb-20",children:n.jsx("code",{className:"text-secondary-strong font-aeonik text-md font-normal whitespace-pre",children:t})})]})}const N=i.forwardRef(({className:t,children:e,...o},r)=>n.jsx("code",{ref:r,className:l("inline-flex items-center align-baseline","rounded-md border border-slate-400","bg-swm-brand-80 mx-0.5 h-5 px-1.5 md:h-7","text-md text-primary-foreground font-normal",t),...o,children:e}));N.displayName="InlineCodeBlock";export{I as C,N as I};
