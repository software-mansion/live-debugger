defmodule LiveDebugger.Support.CssQueries do
  @moduledoc """
  This module defines the CSS queries for the LiveDebugger e2e tests.
  """

  import Wallaby.Query

  def toggle_tracing_button(), do: css("button[phx-click=\"switch-tracing\"]")

  def refresh_history_button(), do: css("button[phx-click=\"refresh-history\"]")

  def clear_traces_button(), do: css("button[phx-click=\"clear-traces\"]")

  def settings_button(), do: css("navbar a#settings-button")

  def return_button(), do: css("navbar a#return-button")

  def title(text: text), do: css("h1", text: text)

  def live_sessions(count: count), do: css("#live-sessions > div", count: count)

  def refresh_button(), do: css("button[phx-click=\"refresh\"]")

  def first_link(), do: css("#live-sessions a.live-view-link", count: 1)

  def no_traces_info() do
    css("#global-traces-stream-empty", text: "No traces have been recorded yet.")
  end

  def sidebar_basic_info() do
    css("#sidebar-content-slide-over-basic-info")
  end

  def search_bar() do
    css("#trace-search-input")
  end
end
