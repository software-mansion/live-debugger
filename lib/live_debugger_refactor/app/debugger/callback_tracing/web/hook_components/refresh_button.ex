defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.HookComponents.RefreshButton do
  @moduledoc """
  This component is used to refresh the traces.
  """

  use LiveDebuggerRefactor.App.Web, :hook_component

  @impl true
  def init(socket) do
    socket
    |> attach_hook(:refresh_button, :handle_event, &handle_event/3)
    |> register_hook(:refresh_button)
  end

  attr(:label_class, :string, default: "")

  @impl true
  def render(assigns) do
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

  defp handle_event("refresh-history", _, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
