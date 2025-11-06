import { CodeBlock } from "./CodeBlock";
import { InlineCodeBlock } from "./InlineCodeBlock";

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
        Add <InlineCodeBlock>live_debugger</InlineCodeBlock> to your list of
        dependencies in <InlineCodeBlock>mix.exs</InlineCodeBlock> :
      </p>
      <div className="mb-3 sm:mb-5 md:mb-10">
        <CodeBlock codeString={mixCode1} />
      </div>

      <p className="text-primary-foreground text-md font-normal">
        Add a line to your application root layout. It attaches{" "}
        <InlineCodeBlock>meta</InlineCodeBlock> tag and LiveDebugger scripts.
      </p>
      <div className="mb-3 sm:mb-5 md:mb-10">
        <CodeBlock codeString={mixCode2} />
      </div>

      <p className="text-primary-foreground text-md font-normal">
        After you start your application, LiveDebugger will be running at a
        default port <InlineCodeBlock>http://localhost:4007</InlineCodeBlock>.
      </p>
    </div>
  );
}
