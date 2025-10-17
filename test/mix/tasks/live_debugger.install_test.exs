defmodule Mix.Tasks.LiveDebugger.InstallTest do
  use ExUnit.Case

  import Igniter.Test

  @moduletag :igniter

  test "installation does not cause any errors on a new phoenix project" do
    phx_test_project()
    |> Igniter.compose_task("live_debugger.install")
    |> apply_igniter!()
  end

  test "installation is idempotent" do
    assert {:ok, _igniter, %{warnings: [], notices: []}} =
             phx_test_project()
             |> Igniter.compose_task("live_debugger.install")
             |> apply_igniter!()
             |> Igniter.compose_task("live_debugger.install")
             |> assert_unchanged()
             |> apply_igniter()
  end

  test "installation modifies the root layout" do
    phx_test_project()
    |> Igniter.compose_task("live_debugger.install")
    |> assert_has_patch("lib/test_web/components/layouts/root.html.heex", """
    + |    <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
    """)
  end

  test "installation notifies the user to modify their root layout if it does not match expected" do
    phx_test_project()
    |> Igniter.update_file("lib/test_web/components/layouts/root.html.heex", fn source ->
      Rewrite.Source.update(source, :content, "<div>Some stuff</div>")
    end)
    |> apply_igniter!()
    |> Igniter.compose_task("live_debugger.install")
    |> assert_unchanged("lib/test_web/components/layouts/root.html.heex")
    |> assert_has_notice("""
    Live Debugger:

    Could not automatically modify root layout.
    Include live_debugger in the `<head>` of your root layout.

        <head>
          <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
        </head>
    """)
  end

  test "installation notifies if the user may need to modify their csp" do
    phx_test_project()
    |> Igniter.Libs.Phoenix.add_pipeline(
      :example,
      """
      plug :put_secure_browser_headers, %{}
      """,
      router: TestWeb.Router
    )
    |> apply_igniter!()
    |> Igniter.compose_task("live_debugger.install")
    |> assert_has_notice("""
    Live Debugger:

    You may need to extend your CSP in :dev mode. For example:

        @csp "{...your CSP} "

          pipeline :browser do
            # ...
            plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
    """)
  end
end
