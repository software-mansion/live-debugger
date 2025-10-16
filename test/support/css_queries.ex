defmodule LiveDebugger.Support.CssQueries do
  @moduledoc """
  This module defines the CSS queries for the LiveDebugger e2e tests.
  """

  import Wallaby.Query

  def toggle_tracing_button(opts \\ []), do: css("button[phx-click=\"switch-tracing\"]", opts)

  def refresh_history_button, do: css("button[phx-click=\"refresh-history\"]")

  def clear_traces_button, do: css("button[phx-click=\"clear-traces\"]")

  def settings_button, do: css("navbar a#settings-button")

  def return_button, do: css("navbar a#return-button")

  def title(text: text), do: css("h1", text: text)

  def live_sessions(count: count), do: css("#live-sessions > div", count: count)

  def refresh_button, do: css("button[phx-click=\"refresh\"]")

  def first_link, do: css("#live-sessions a.live-view-link", count: 1)

  def live_component(id), do: css("div[data-phx-component=\"#{id}\"]")

  def switch_inspect_mode_button, do: css("button[phx-click=\"switch-inspect-mode\"]")

  def no_traces_info do
    css("#global-traces-stream-empty", text: "No traces have been recorded yet.")
  end

  def sidebar_basic_info do
    css("#node-inspector-basic-info")
  end

  def search_bar do
    css("#trace-search-input")
  end

  def assigns_search_bar do
    css("#assigns-search-input")
  end

  def assigns_search_bar_fullscreen do
    css("#assigns-search-input-fullscreen")
  end

  def inspect_tooltip_module_text(text) do
    css("div#live-debugger-tooltip div.live-debugger-tooltip-module", text: text)
  end

  def inspect_tooltip_type_text(text) do
    css("div#live-debugger-tooltip span.type-text", text: text)
  end

  def inspect_tooltip_value_text(text) do
    css("div#live-debugger-tooltip span.value", text: text)
  end
end
