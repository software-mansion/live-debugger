import { CodeBlock } from "./CodeBlock";
import { InlineCode } from "./InlineCode";

const mixCode1 = `defp deps do
  [
    {:live_debugger, "~> 0.4.0", only: :dev}
  ]
end`;

const mixCode2 = `# lib/my_app_web/components/layouts/root.html.heex

<head>
  <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
</head>`;

export default function MixInstallTab() {
  return (
    <div className="flex flex-col gap-6">
      <p className="text-primary-foreground text-md font-normal">
        Add <InlineCode>live_debugger</InlineCode> to your list of dependencies
        in <InlineCode>mix.exs</InlineCode> :
      </p>
      <CodeBlock codeString={mixCode1} />

      <br />

      <p className="text-primary-foreground text-md font-normal">
        Add a line to your application root layout. It attaches{" "}
        <InlineCode>meta</InlineCode> tag and LiveDebugger scripts.
      </p>
      <CodeBlock codeString={mixCode2} />

      <br />

      <p className="text-primary-foreground text-md font-normal">
        After you start your application, LiveDebugger will be running at a
        default port <InlineCode>http://localhost:4007</InlineCode>.
      </p>
    </div>
  );
}
