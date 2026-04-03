defmodule LiveDebugger.Tour do
  @moduledoc """
  Elixir API for controlling the LiveDebugger tour.

  Returns `Phoenix.LiveView.JS` commands that can be used directly in templates
  with `phx-click`, `phx-mounted`, etc.

  ## Usage in templates

      <button phx-click={Tour.spotlight(:send_event_button)}>
        Click Send Event
      </button>

      <button phx-click={Tour.clear()}>
        Clear
      </button>

  ## Usage with raw element IDs

      <button phx-click={Tour.highlight("my-custom-id", "click-target")}>
        Highlight
      </button>
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
    dispatch("spotlight", resolve_target(target), dismiss)
  end

  @doc """
  Highlight an element — outlines it without blocking the page.
  Default dismiss: `"click-anywhere"`.
  """
  @spec highlight(atom() | String.t(), dismiss()) :: JS.t()
  def highlight(target, dismiss \\ "click-anywhere") do
    dispatch("highlight", resolve_target(target), dismiss)
  end

  @doc """
  Clear all tour effects.
  """
  @spec clear() :: JS.t()
  def clear do
    JS.dispatch("lvdbg:tour-action", detail: %{action: "clear"})
  end

  @doc """
  Enable settings toggles in the debugger.
  """
  @spec enable_settings() :: JS.t()
  def enable_settings do
    JS.dispatch("lvdbg:tour-action", detail: %{action: "settings-enabled"})
  end

  @doc """
  Disable settings toggles in the debugger.
  """
  @spec disable_settings() :: JS.t()
  def disable_settings do
    JS.dispatch("lvdbg:tour-action", detail: %{action: "settings-disabled"})
  end

  defp dispatch(action, target, dismiss) do
    JS.dispatch("lvdbg:tour-action",
      detail: %{action: action, target: target, dismiss: dismiss}
    )
  end

  defp resolve_target(name) when is_atom(name), do: TourElements.id!(name)
  defp resolve_target(id) when is_binary(id), do: id
end
