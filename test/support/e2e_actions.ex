defmodule LiveDebugger.Support.E2EActions do
  @moduledoc """
  This module defines the actions for the LiveDebugger e2e tests.
  """

  import Wallaby.Browser
  import LiveDebugger.Support.CssQueries

  def select_live_view(parent, pid, opts \\ []) do
    parent
    |> hover(live_view_button(pid, opts))
    |> click(live_view_button(pid, opts))
  end

  def get_dev_pid(session) do
    if has_css?(session, "#current-pid") do
      do_get_dev_pid(session)
    else
      # Sometimes the PID is not available immediately, so we wait for it
      Process.sleep(500)

      do_get_dev_pid(session)
    end
  end

  defp do_get_dev_pid(session) do
    session
    |> Wallaby.Browser.find(Wallaby.Query.css("#current-pid"))
    |> Wallaby.Element.text()
  end
end
