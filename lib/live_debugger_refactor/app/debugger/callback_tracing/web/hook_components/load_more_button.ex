defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.HookComponents.LoadMoreButton do
  @moduledoc """
  This component is used to load more traces.
  It uses `trace_continuation` to determine if there are more traces to load.
  """

  use LiveDebuggerRefactor.App.Web, :hook_component

  @required_assigns [:lv_process, :traces_continuation, :current_filters]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> attach_hook(:load_more_button, :handle_event, &handle_event/3)
    |> register_hook(:load_more_button)
  end

  attr(:traces_continuation, :any, required: true)

  @impl true
  def render(%{traces_continuation: nil} = assigns), do: ~H""
  def render(%{traces_continuation: :end_of_table} = assigns), do: ~H""

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <.content traces_continuation={@traces_continuation} />
    </div>
    """
  end

  defp content(%{traces_continuation: :loading} = assigns) do
    ~H"""
    <.spinner size="sm" />
    """
  end

  defp content(%{traces_continuation: :error} = assigns) do
    ~H"""
    <.alert with_icon={true} heading="Error while loading more traces" class="w-full">
      Check logs for more details.
    </.alert>
    """
  end

  defp content(%{traces_continuation: cont} = assigns) when is_tuple(cont) do
    ~H"""
    <.button phx-click="load-more" class="w-4" variant="secondary">
      Load more
    </.button>
    """
  end

  defp handle_event("load-more", _, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
