defmodule LiveDebugger.LiveComponents.NestedLiveViewsLinks do
  @moduledoc """
  List of links to LvProcesses nested inside `lv_process`
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Components.Links
  alias LiveDebugger.Services.LiveViewDiscoveryService

  @impl true
  def update(%{refresh: true}, socket) do
    socket
    |> assign_async_nested_lv_processes()
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(:lv_process, assigns.lv_process)
    |> assign_async_nested_lv_processes()
    |> ok()
  end

  attr(:lv_process, LvProcess, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full px-4 py-3 gap-3 flex flex-col border-b border-default-border">
      <.async_result :let={nested_lv_processes} assign={@nested_lv_processes}>
        <:loading>
          <.spinner size="sm" class="m-auto" />
        </:loading>
        <.nested_live_views_links_label nested_lv_processes={nested_lv_processes} />
        <%= unless Enum.empty?(nested_lv_processes) do %>
          <div class="pl-2 flex flex-col gap-1">
            <Links.live_view
              :for={{nested_lv_process, index} <- Enum.with_index(nested_lv_processes)}
              lv_process={nested_lv_process}
              id={"nested_live_view_link_#{index}"}
              icon="icon-nested"
            />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  attr(:nested_lv_processes, :any, required: true)

  defp nested_live_views_links_label(assigns) do
    label =
      if Enum.empty?(assigns.nested_lv_processes) do
        "No nested LiveViews"
      else
        "Nested LiveViews"
      end

    assigns = assign(assigns, :label, label)

    ~H"""
    <p class="pl-2 shrink-0 font-medium text-secondary-text"><%= @label %></p>
    """
  end

  defp assign_async_nested_lv_processes(socket) do
    pid = socket.assigns.lv_process.pid

    assign_async(socket, :nested_lv_processes, fn ->
      {:ok, %{nested_lv_processes: LiveViewDiscoveryService.children_lv_processes(pid)}}
    end)
  end
end
