import{j as e}from"./utils.CP-DEBaU.js";import{I as t,C as o}from"./InlineCodeBlock.ChDW6TxE.js";import"./index.S7Dpkimb.js";import"./button.CrUktQAm.js";import"./index.-KpfnFlO.js";import"./index.CwgFG58H.js";import"./createLucideIcon.rtP_7z7L.js";const r=`defp deps do
  [
    {:live_debugger, "~> 0.4.0", only: :dev}
  ]
end`,i=`# lib/my_app_web/components/layouts/root.html.heex

<head>
  <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
</head>`;function p(){return e.jsxs("div",{className:"flex flex-col gap-6",children:[e.jsxs("p",{className:"text-primary-foreground text-md font-normal",children:["Add ",e.jsx(t,{children:"live_debugger"})," to your list of dependencies in ",e.jsx(t,{children:"mix.exs"})," :"]}),e.jsx("div",{className:"mb-3 sm:mb-5 md:mb-10",children:e.jsx(o,{codeString:r})}),e.jsxs("p",{className:"text-primary-foreground text-md font-normal",children:["Add a line to your application root layout. It attaches"," ",e.jsx(t,{children:"meta"})," tag and LiveDebugger scripts."]}),e.jsx("div",{className:"mb-3 sm:mb-5 md:mb-10",children:e.jsx(o,{codeString:i})}),e.jsxs("p",{className:"text-primary-foreground text-md font-normal",children:["After you start your application, LiveDebugger will be running at a default port ",e.jsx(t,{children:"http://localhost:4007"}),"."]})]})}export{p as default};
