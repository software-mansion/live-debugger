defmodule LiveDebugger.App.Debugger.Resources.Web.ResourcesLive do
  @moduledoc """
  Nested LiveView for displaying resources information for the LiveView process.
  """

  use LiveDebugger.App.Web, :live_view

  require Logger

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered
  alias LiveDebugger.App.Debugger.Resources.Actions.ProcessInfo, as: ProcessInfoActions
  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias LiveDebugger.Utils.Memory
  alias LiveDebugger.App.Debugger.Resources.Components.Chart
  alias LiveDebugger.App.Debugger.Resources.Components

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  @keys_order ~w(
    initial_call
    current_function
    registered_name
    status
    message_queue_len
    priority
    reductions
    memory
    total_heap_size
    heap_size
    stack_size
  )a

  @memory_keys ~w(memory total_heap_size heap_size stack_size)a

  @refresh_interval 1000

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
    |> assign(id: id)
    |> assign(parent_pid: parent_pid)
    |> assign(lv_process: lv_process)
    |> assign(keys_order: @keys_order)
    |> assign(refresh_interval: @refresh_interval)
    |> assign(process_info: AsyncResult.loading())
    |> assign_async_process_info()
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
        <.section
          title="Process Information"
          id="process-info"
          inner_class="mx-0 my-4 px-4"
          class="flex-1"
        >
          <:right_panel>
            <Components.refresh_select
              id="refresh-select"
              name="refresh-select"
              selected_interval={@refresh_interval}
            />
          </:right_panel>
          <.async_result :let={process_info} assign={@process_info}>
            <:loading>
              <p>Loading...</p>
            </:loading>
            <:failed>
              <p>Failed to fetch process information</p>
            </:failed>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-2 w-full">
              <.process_info process_info={process_info} />
              <Chart.render id="process-info-chart" class="min-h-[36vh]" />
            </div>
          </.async_result>
        </.section>
      </div>
    </div>
    """
  end

  @impl true
  def handle_async(:process_info, {:ok, process_info}, socket) do
    Process.send_after(self(), :refresh_process_info, @refresh_interval)

    socket
    |> assign(process_info: AsyncResult.ok(socket.assigns.process_info, process_info))
    |> Chart.append_new_data(process_info)
    |> noreply()
  end

  def handle_async(:process_info, {:exit, reason}, socket) do
    Logger.error("Failed to fetch process information: #{inspect(reason)}")

    socket
    |> assign(process_info: AsyncResult.failed(socket.assigns.process_info, reason))
    |> noreply()
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

  def handle_info(:refresh_process_info, socket) do
    socket
    |> assign_async_process_info()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("change_refresh_interval", %{"refresh-select" => value}, socket) do
    refresh_interval = String.to_integer(value)
    dbg(refresh_interval)

    socket
    |> assign(refresh_interval: refresh_interval)
    |> noreply()
  end

  attr(:process_info, ProcessInfo, required: true)

  defp process_info(assigns) do
    assigns = assign(assigns, keys_order: @keys_order)

    ~H"""
    <div>
      <%= for key <- @keys_order do %>
        <div class="flex py-1">
          <span class="font-medium w-36 flex-shrink-0"><%= display_key(key) %>:</span>
          <span class={"font-code #{value_color_class(key)} truncate"}>
            <%= @process_info |> Map.get(key) |> display_value(key) %>
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  defp assign_async_process_info(socket) do
    pid = socket.assigns.lv_process.pid

    socket
    |> start_async(:process_info, fn ->
      case ProcessInfoActions.get_info(pid) do
        {:ok, process_info} -> process_info
        {:error, reason} -> raise reason
      end
    end)
  end

  defp display_key(key) do
    key
    |> to_string()
    |> String.replace(":", " ")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp value_color_class(:message_queue_len), do: "text-code-1"
  defp value_color_class(:reductions), do: "text-code-1"
  defp value_color_class(:memory), do: "text-code-4"
  defp value_color_class(:total_heap_size), do: "text-code-4"
  defp value_color_class(:heap_size), do: "text-code-4"
  defp value_color_class(:stack_size), do: "text-code-4"
  defp value_color_class(_), do: "text-code-2"

  defp display_value(mfa, :current_function), do: mfa_to_string(mfa)
  defp display_value(mfa, :initial_call), do: mfa_to_string(mfa)
  defp display_value(priority, :priority), do: "#{priority}"
  defp display_value(status, :status), do: "#{status}"
  defp display_value([], :registered_name), do: ""

  defp display_value(size, key) when key in @memory_keys do
    Memory.bytes_to_pretty_string(size)
  end

  defp display_value(value, _key), do: inspect(value)

  defp mfa_to_string({module, function, arity}) do
    "#{inspect(module)}.#{function}/#{arity}"
  end
end
