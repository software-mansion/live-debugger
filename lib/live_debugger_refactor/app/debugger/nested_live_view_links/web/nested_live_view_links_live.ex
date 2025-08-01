defmodule LiveDebuggerRefactor.App.Debugger.NestedLiveViewLinks.Web.NestedLiveViewLinksLive do
  use LiveDebuggerRefactor.App.Web, :live_view

  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.API.LiveViewDiscovery
  alias LiveDebuggerRefactor.App.Debugger.Web.Components, as: DebuggerComponents

  @doc """
  Renders the `NodeStateLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  """
  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]

    socket
    |> assign(lv_process: lv_process)
    |> assign_async_nested_lv_processes()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full px-4 py-3 gap-3 flex flex-col border-b border-default-border">
      <.async_result :let={nested_lv_processes} assign={@nested_lv_processes}>
        <:loading>
          <.spinner size="sm" class="m-auto" />
        </:loading>
        <p class="pl-2 shrink-0 font-medium text-secondary-text">
          <%= if Enum.empty?(nested_lv_processes), do: "No nested LiveViews", else: "Nested LiveViews" %>
        </p>
        <%= if not Enum.empty?(nested_lv_processes) do %>
          <div class="pl-2 flex flex-col gap-1">
            <DebuggerComponents.live_view_link
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

  defp assign_async_nested_lv_processes(%{assigns: %{lv_process: %{pid: pid}}} = socket) do
    assign_async(socket, :nested_lv_processes, fn ->
      {:ok, %{nested_lv_processes: LiveViewDiscovery.children_lv_processes(pid)}}
    end)
  end
end
