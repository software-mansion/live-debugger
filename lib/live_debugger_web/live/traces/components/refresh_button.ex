defmodule LiveDebuggerWeb.Live.Traces.Components.RefreshButton do
  @moduledoc """
  This component is used to refresh the traces.
  It produces the `refresh-history` event that can be handled by the hook provided in the `init/1` function.
  It depends on the `existing_traces` hook to be initialized.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Live.Traces.Hooks

  @doc """
  Initializes the component by checking the assigns and attaching the hook to the socket.
  The hook is used to handle the `refresh-history` event.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> attach_hook(:refresh_button, :handle_event, &handle_event/3)
    |> register_hook(:refresh_button)
  end

  @doc """
  Renders the refresh button.
  It produces the `refresh-history` event that can be handled by the hook provided in the `init/1` function.
  """
  attr(:label_class, :string, default: "")

  @spec refresh_button(map()) :: Phoenix.LiveView.Rendered.t()
  def refresh_button(assigns) do
    ~H"""
    <.button
      phx-click="refresh-history"
      aria-label="Refresh traces"
      class="flex gap-2"
      variant="secondary"
      size="sm"
    >
      <.icon name="icon-refresh" class="w-4 h-4" />
      <div class={@label_class}>
        Refresh
      </div>
    </.button>
    """
  end

  defp handle_event("refresh-history", _, socket) do
    socket
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
