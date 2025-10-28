defmodule LiveDebugger.App.Debugger.Resources.Web.ResourcesLive do
  @moduledoc """
  Nested LiveView for displaying resources information for the LiveView process.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "id" => assigns.id,
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
  def mount(
        _params,
        %{"parent_pid" => parent_pid, "lv_process" => lv_process, "id" => id},
        socket
      ) do
    if connected?(socket) do
      Bus.receive_events!(parent_pid)
    end

    socket
    |> assign(
      id: id,
      parent_pid: parent_pid,
      lv_process: lv_process
    )
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grow p-8 overflow-y-auto scrollbar-main">
      <div class="w-full min-w-[25rem] max-w-screen-2xl mx-auto">
        <div class="flex flex-col gap-1.5 pb-6 px-0.5">
          <.h1>Resources</.h1>
          <span class="text-secondary-text">
            This view will display resource information for the debugged LiveView
          </span>
        </div>
        <div class="@container/resources w-full min-w-[20rem] flex flex-col pt-2 shadow-custom rounded-sm bg-surface-0-bg border border-default-border">
          <div class="flex flex-1 overflow-auto rounded-sm bg-surface-0-bg p-4">
            <div class="w-full h-full flex flex-col gap-4 items-center justify-center text-secondary-text">
              <p>This page is empty.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(
        %DeadViewModeEntered{debugger_pid: pid},
        %{assigns: %{parent_pid: pid}} = socket
      ) do
    socket
    |> assign(:lv_process, socket.assigns.lv_process |> LvProcess.set_alive(false))
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
