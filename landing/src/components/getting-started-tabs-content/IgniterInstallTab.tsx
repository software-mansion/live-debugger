import { CodeBlock } from "./CodeBlock";
import { InlineCode } from "./InlineCode";

const mixCode = `mix igniter.install live_debugger`;

export default function IgniterInstallTab() {
  return (
    <div className="flex flex-col gap-6">
      <p className="text-primary-foreground text-md font-normal">
        LiveDebugger has Igniter support. It'll automatically add LiveDebugger
        dependency and modify your <InlineCode>root.html.heex</InlineCode> after
        you use the below command.
      </p>
      <CodeBlock codeString={mixCode} />
    </div>
  );
}
