defmodule LiveDebugger.Tour do
  @moduledoc """
  Elixir API for controlling the LiveDebugger tour.

  Returns `Phoenix.LiveView.JS` commands that dispatch DOM events picked up
  by the injected client JS (`assets/client/services/tour.js`), which forwards
  them through the WebSocket channel as `tour:<command>` messages.

  ## Usage in templates

      alias LiveDebugger.Tour

      <button phx-click={Tour.spotlight(:send_event_button)}>Spotlight</button>
      <button phx-click={Tour.highlight(:navbar_connected)}>Highlight</button>
      <button phx-click={Tour.clear()}>Clear</button>
      <button phx-click={Tour.redirect("/path", then: Tour.step(:spotlight, :element))}>Redirect</button>
  """

  alias Phoenix.LiveView.JS
  alias LiveDebugger.TourElements

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()
  @type dismiss :: String.t()

  @doc """
  Spotlight an element — dims everything except the target.
  Default dismiss: `"click-target"`.
  """
  @spec spotlight(atom() | String.t(), dismiss()) :: JS.t()
  def spotlight(target, dismiss \\ "click-target") do
    dispatch("tour:spotlight", %{target: resolve_target(target), dismiss: dismiss})
  end

  @doc """
  Highlight an element — outlines it without blocking the page.
  Default dismiss: `"click-anywhere"`.
  """
  @spec highlight(atom() | String.t(), dismiss()) :: JS.t()
  def highlight(target, dismiss \\ "click-anywhere") do
    dispatch("tour:highlight", %{target: resolve_target(target), dismiss: dismiss})
  end

  @doc """
  Redirect the debugger to a URL, optionally applying a tour step after arrival.

  ## Examples

      Tour.redirect_JS("/debugger/pid")
      Tour.redirect_JS("/debugger/pid", then: Tour.step(:spotlight, :send_event_button))
  """
  @spec redirect_JS(String.t(), keyword()) :: JS.t()
  def redirect_JS(url, opts \\ []) do
    payload = %{url: url}

    payload =
      case Keyword.get(opts, :then) do
        nil -> payload
        step when is_map(step) -> Map.put(payload, :then, step)
      end

    dispatch("tour:redirect", payload)
  end

  @spec redirect(String.t()) :: :ok
  def redirect(url) do
    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:tour:receive",
      {"tour:redirect", %{"url" => url}}
    )
  end

  @doc """
  Build a step map for use with `redirect/2`'s `:then` option.

  ## Examples

      Tour.step(:spotlight, :send_event_button)
      Tour.step(:highlight, :navbar_connected, "click-target")
  """
  @spec step(:spotlight | :highlight, atom() | String.t(), dismiss()) :: map()
  def step(action, target, dismiss \\ nil)

  def step(:spotlight, target, dismiss) do
    %{action: "spotlight", target: resolve_target(target), dismiss: dismiss || "click-target"}
  end

  def step(:highlight, target, dismiss) do
    %{action: "highlight", target: resolve_target(target), dismiss: dismiss || "click-anywhere"}
  end

  @doc """
  Clear all tour effects.
  """
  @spec clear() :: JS.t()
  def clear do
    dispatch("tour:clear", %{})
  end

  @doc """
  Enable settings toggles in the debugger.
  """
  @spec enable_settings() :: JS.t()
  def enable_settings do
    dispatch("tour:settings-enabled", %{})
  end

  @doc """
  Disable settings toggles in the debugger.
  """
  @spec disable_settings() :: JS.t()
  def disable_settings do
    dispatch("tour:settings-disabled", %{})
  end

  defp dispatch(command, payload) do
    JS.dispatch("lvdbg:tour", detail: Map.put(payload, :command, command))
  end

  defp resolve_target(name) when is_atom(name), do: TourElements.id!(name)
  defp resolve_target(id) when is_binary(id), do: id
end
