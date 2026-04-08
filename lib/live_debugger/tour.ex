defmodule LiveDebugger.Tour do
  @moduledoc """
  Elixir API for controlling the LiveDebugger tour.

  Returns `Phoenix.LiveView.JS` commands that dispatch DOM events picked up
  by the injected client JS (`assets/client/services/tour.js`), which forwards
  them through the WebSocket channel as `tour:<command>` messages.

  ## Message convention

  Each function maps to a channel message:

      spotlight/2  → "tour:spotlight"  {target, dismiss}
      highlight/2  → "tour:highlight"  {target, dismiss}
      clear/0      → "tour:clear"      {}
      enable_settings/0  → "tour:settings-enabled"  {}
      disable_settings/0 → "tour:settings-disabled"  {}

  ## Usage in templates

      alias LiveDebugger.Tour

      <button phx-click={Tour.spotlight(:send_event_button)}>Click Send Event</button>
      <button phx-click={Tour.highlight(:navbar_connected)}>Highlight PID</button>
      <button phx-click={Tour.clear()}>Clear</button>
  """

  alias Phoenix.LiveView.JS
  alias LiveDebugger.TourElements

  @type dismiss :: String.t()

  @doc """
  Spotlight an element — dims everything except the target.
  Default dismiss: `"click-target"`.

  Accepts an atom (looked up in `TourElements`) or a string element ID.
  """
  @spec spotlight(atom() | String.t(), dismiss()) :: JS.t()
  def spotlight(target, dismiss \\ "click-target") do
    JS.dispatch("lvdbg:tour",
      detail: %{command: "tour:spotlight", target: resolve_target(target), dismiss: dismiss}
    )
  end

  @doc """
  Highlight an element — outlines it without blocking the page.
  Default dismiss: `"click-anywhere"`.
  """
  @spec highlight(atom() | String.t(), dismiss()) :: JS.t()
  def highlight(target, dismiss \\ "click-anywhere") do
    JS.dispatch("lvdbg:tour",
      detail: %{command: "tour:highlight", target: resolve_target(target), dismiss: dismiss}
    )
  end

  @doc """
  Clear all tour effects.
  """
  @spec clear() :: JS.t()
  def clear do
    JS.dispatch("lvdbg:tour", detail: %{command: "tour:clear"})
  end

  @doc """
  Enable settings toggles in the debugger.
  """
  @spec enable_settings() :: JS.t()
  def enable_settings do
    JS.dispatch("lvdbg:tour", detail: %{command: "tour:settings-enabled"})
  end

  @doc """
  Disable settings toggles in the debugger.
  """
  @spec disable_settings() :: JS.t()
  def disable_settings do
    JS.dispatch("lvdbg:tour", detail: %{command: "tour:settings-disabled"})
  end

  defp resolve_target(name) when is_atom(name), do: TourElements.id!(name)
  defp resolve_target(id) when is_binary(id), do: id
end
