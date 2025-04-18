defmodule Mix.Tasks.LiveDebugger.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs live_debugger. Use `mix igniter.install live_debugger` to call. Requires igniter to run."
  end

  def example do
    "mix igniter.install live_debugger"
  end

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.LiveDebugger.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    @root_layout_notice """
    Live Debugger:

    Could not automatically modify root layout.
    Include live_debugger in the `<head>` of your root layout.

        <head>
          <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
        </head>
    """

    @csp_notice """
    Live Debugger:

    You may need to extend your CSP in :dev mode. For example:

        @csp "{...your CSP} #{if Mix.env() == :dev, do: "http://127.0.0.1:4007"}"

          pipeline :browser do
            # ...
            plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
    """

    @script_tag """
        <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :live_debugger,
        example: __MODULE__.Docs.example(),
        only: [:dev]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> setup_root_layout()
      |> notify_csp()
    end

    defp notify_csp(igniter) do
      {igniter, routers} = Igniter.Libs.Phoenix.list_routers(igniter)

      {igniter, any_router_has_configured_csp?} =
        Enum.reduce_while(routers, {igniter, false}, fn router, {igniter, false} ->
          {igniter, _source, zipper} =
            Igniter.Project.Module.find_module!(igniter, router)

          # Right now we just check if they are configuring "anything" in this plug
          # i.e not just using `plug :put_secure_browser_headers`
          # we could theoretically try to check for if they are including the
          # "content-security-policy" key, but since this is just a notice, its
          # better to be eager about it
          if has_configured_scure_browser_headers?(zipper) do
            {:halt, {igniter, true}}
          else
            {:cont, {igniter, false}}
          end
        end)

      if any_router_has_configured_csp? do
        Igniter.add_notice(igniter, @csp_notice)
      else
        igniter
      end
    end

    defp has_configured_scure_browser_headers?(zipper) do
      match?(
        {:ok, _},
        Igniter.Code.Common.move_to(zipper, fn zipper ->
          Igniter.Code.Function.function_call?(
            zipper,
            :plug,
            2
          ) and
            Igniter.Code.Function.argument_equals?(
              zipper,
              0,
              :put_secure_browser_headers
            )
        end)
      )
    end

    defp setup_root_layout(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)
      root_layout = Path.join(["lib", "#{app_name}_web", "components/layouts/root.html.heex"])

      if Igniter.exists?(igniter, root_layout) do
        Igniter.update_file(igniter, root_layout, &replace_script_tag/1)
      else
        Igniter.add_notice(igniter, @root_layout_notice)
      end
    end

    defp replace_script_tag(source) do
      contents = Rewrite.Source.get(source, :content)

      if String.contains?(contents, ":live_debugger") do
        source
      else
        do_replace_script_tag(source, contents)
      end
    end

    defp do_replace_script_tag(source, contents) do
      case String.split(contents, "<head>", parts: 2) do
        [lead, tail] ->
          contents =
            "#{lead}<head>\n#{@script_tag}#{tail}"

          Rewrite.Source.update(source, :content, contents)

        _ ->
          {:notice, @root_layout_notice}
      end
    end
  end
else
  defmodule Mix.Tasks.LiveDebugger.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'live_debugger.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
