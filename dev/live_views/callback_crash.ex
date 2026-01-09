defmodule LiveDebuggerDev.LiveViews.CallbackCrash do
  use DevWeb, :live_view

  def mount(params, _session, socket) do
    if params["crash_in"] == "mount" do
      raise "Crash inside MOUNT callback"
    end

    {:ok, assign(socket, crash_render: false, crash_terminate: false)}
  end

  def handle_params(params, _uri, socket) do
    if params["crash_in"] == "params" do
      raise "Crash inside HANDLE_PARAMS callback"
    end

    {:noreply, socket}
  end

  def render(assigns) do
    if assigns.crash_render do
      raise "Crash inside RENDER callback"
    end

    ~H"""
    <div class="p-8 max-w-4xl mx-auto">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.card title="1. Initialization & URL">
          <p class="text-sm text-gray-500 mb-2">Reloads page with query param</p>
          <div class="flex gap-2 flex-wrap">
            <.link href="?crash_in=mount" class="btn-red">Crash MOUNT</.link>
            <.link href="?crash_in=params" class="btn-red">Crash HANDLE_PARAMS</.link>
            <.link href="?" class="btn-green">Reset URL</.link>
          </div>
        </.card>

        <.card title="2. Event Loop Handlers">
          <div class="flex flex-col gap-2">
            <.button phx-click="crash_event" class="btn-blue">
              handle_event
            </.button>

            <.button phx-click="trigger_info" class="btn-orange">
              handle_info
            </.button>

            <.button phx-click="trigger_cast" class="btn-purple">
              handle_cast
            </.button>

            <.button phx-click="trigger_call" class="btn-purple">
              handle_call
            </.button>
          </div>
        </.card>

        <.card title="3. Async & Render">
          <div class="flex flex-col gap-2">
            <.button phx-click="trigger_async" class="btn-teal">
              handle_async
            </.button>

            <.button phx-click="trigger_render" class="btn-pink">
              render
            </.button>
          </div>
        </.card>
      </div>
    </div>
    """
  end

  def handle_event("crash_event", _params, _socket) do
    raise "Crash inside HANDLE_EVENT callback"
  end

  def handle_event("trigger_info", _, socket) do
    send(self(), :crash_info)
    {:noreply, socket}
  end

  def handle_event("trigger_cast", _, socket) do
    GenServer.cast(self(), :crash_cast)
    {:noreply, socket}
  end

  def handle_event("trigger_call", _, socket) do
    pid = self()
    Task.start(fn -> GenServer.call(pid, :crash_call) end)
    {:noreply, socket}
  end

  def handle_event("trigger_async", _, socket) do
    {:noreply, start_async(socket, :async_task, fn -> :ok end)}
  end

  def handle_event("trigger_render", _, socket) do
    {:noreply, assign(socket, :crash_render, true)}
  end

  def handle_info(:crash_info, _socket) do
    raise "Crash inside HANDLE_INFO callback"
  end

  def handle_info({_ref, :ok}, socket), do: {:noreply, socket}

  def handle_cast(:crash_cast, _socket) do
    raise "Crash inside HANDLE_CAST callback"
  end

  def handle_call(:crash_call, _from, _socket) do
    raise "Crash inside HANDLE_CALL callback"
  end

  def handle_async(:async_task, {:ok, :ok}, _socket) do
    raise "Crash inside HANDLE_ASYNC callback"
  end

  defp card(assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg p-4 bg-white shadow-sm">
      <h2 class="font-bold text-lg mb-3 border-b pb-2">{@title}</h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
