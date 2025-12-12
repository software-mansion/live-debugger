defmodule LiveDebugger.Support.E2EActions do
  @moduledoc """
  This module defines the actions for the LiveDebugger e2e tests.
  """

  import Wallaby.Browser
  import LiveDebugger.Support.CssQueries

  def select_live_view(parent, opts \\ []) do
    parent
    |> hover(live_view_button(opts))
    |> click(live_view_button(opts))
  end
end
