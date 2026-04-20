defmodule LiveDebugger.Tour do
  @moduledoc """
  Elixir API for controlling the LiveDebugger tour.

  Returns `Phoenix.LiveView.JS` commands that dispatch DOM events picked up
  by the injected client JS (`assets/client/services/tour.js`), which forwards
  them through the WebSocket channel as `tour:<command>` messages, or broadcasts
  them directly via PubSub.

  ## Usage in templates

      alias LiveDebugger.Tour

      <button phx-click={Tour.spotlight_JS(:send_event_button)}>Spotlight</button>
      <button phx-click={Tour.highlight_JS(:navbar_connected, dismiss: "click-target")}>Highlight</button>
      <button phx-click={Tour.highlight_JS(:other_element, clear: false)}>Stack Highlight</button>
      <button phx-click={Tour.clear_JS()}>Clear</button>
      <button phx-click={Tour.redirect_JS("/path", then: Tour.step(:spotlight, :element))}>Redirect</button>
  """

  alias Phoenix.LiveView.JS
  alias LiveDebugger.TourElements

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @type tour_opts :: [dismiss: String.t(), clear: boolean()]

  @doc """
  Spotlight an element via JS command — dims everything except the target.
  Default dismiss: `"click-target"`.
  """
  @spec spotlight_JS(atom() | String.t(), tour_opts()) :: JS.t()
  def spotlight_JS(target, opts \\ []) do
    dismiss = Keyword.get(opts, :dismiss, "click-target")
    clear = Keyword.get(opts, :clear, true)
    dispatch("tour:spotlight", %{target: resolve_target(target), dismiss: dismiss, clear: clear})
  end

  @doc """
  Spotlight an element via PubSub broadcast.
  """
  @spec spotlight(atom() | String.t(), tour_opts()) :: :ok
  def spotlight(target, opts \\ []) do
    dismiss = Keyword.get(opts, :dismiss, "click-target")
    clear = Keyword.get(opts, :clear, true)

    broadcast("tour:spotlight", %{
      "target" => resolve_target(target),
      "dismiss" => dismiss,
      "clear" => clear
    })
  end

  @doc """
  Highlight an element via JS command — outlines it without blocking the page.
  Default dismiss: `"click-anywhere"`.
  """
  @spec highlight_JS(atom() | String.t(), tour_opts()) :: JS.t()
  def highlight_JS(target, opts \\ []) do
    dismiss = Keyword.get(opts, :dismiss, "click-anywhere")
    clear = Keyword.get(opts, :clear, true)

    dispatch("tour:highlight", %{target: resolve_target(target), dismiss: dismiss, clear: clear})
  end

  @doc """
  Highlight an element via PubSub broadcast.
  """
  @spec highlight(atom() | String.t(), tour_opts()) :: :ok
  def highlight(target, opts \\ []) do
    dismiss = Keyword.get(opts, :dismiss, "click-anywhere")
    clear = Keyword.get(opts, :clear, true)

    broadcast("tour:highlight", %{
      "target" => resolve_target(target),
      "dismiss" => dismiss,
      "clear" => clear
    })
  end

  @doc """
  Redirect the debugger to a URL via JS command, optionally applying a tour step after arrival.
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

  @doc """
  Redirect the debugger to a URL via PubSub broadcast.
  """
  @spec redirect(String.t()) :: :ok
  def redirect(url) do
    broadcast("tour:redirect", %{"url" => url})
  end

  @doc """
  Build a step map for use with `redirect_JS/2`'s `:then` option.
  """
  @spec step(:spotlight | :highlight, atom() | String.t(), tour_opts()) :: map()
  def step(action, target, opts \\ [])

  def step(:spotlight, target, opts) do
    dismiss = Keyword.get(opts, :dismiss, "click-target")
    clear = Keyword.get(opts, :clear, true)

    %{action: "spotlight", target: resolve_target(target), dismiss: dismiss, clear: clear}
  end

  def step(:highlight, target, opts) do
    dismiss = Keyword.get(opts, :dismiss, "click-anywhere")
    clear = Keyword.get(opts, :clear, true)

    %{action: "highlight", target: resolve_target(target), dismiss: dismiss, clear: clear}
  end

  @doc """
  Clear all tour effects via JS command.
  """
  @spec clear_JS() :: JS.t()
  def clear_JS do
    dispatch("tour:clear", %{})
  end

  @doc """
  Clear all tour effects via PubSub broadcast.
  """
  @spec clear() :: :ok
  def clear do
    broadcast("tour:clear", %{})
  end

  @doc """
  Enable settings toggles in the debugger via JS command.
  """
  @spec enable_settings_JS() :: JS.t()
  def enable_settings_JS do
    dispatch("tour:settings-enabled", %{})
  end

  @doc """
  Enable settings toggles in the debugger via PubSub broadcast.
  """
  @spec enable_settings() :: :ok
  def enable_settings do
    broadcast("tour:settings-enabled", %{})
  end

  @doc """
  Disable settings toggles in the debugger via JS command.
  """
  @spec disable_settings_JS() :: JS.t()
  def disable_settings_JS do
    dispatch("tour:settings-disabled", %{})
  end

  @doc """
  Disable settings toggles in the debugger via PubSub broadcast.
  """
  @spec disable_settings() :: :ok
  def disable_settings do
    broadcast("tour:settings-disabled", %{})
  end

  defp dispatch(command, payload) do
    JS.dispatch("lvdbg:tour", detail: Map.put(payload, :command, command))
  end

  defp broadcast(command, payload) do
    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:tour:receive",
      {command, payload}
    )
  end

  defp resolve_target(name) when is_atom(name), do: TourElements.id!(name)
  defp resolve_target(id) when is_binary(id), do: id
end
