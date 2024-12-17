defmodule LiveDebugger.Services.CallbackTracer do
  use GenServer

  alias LiveDebugger.Services.ModuleDiscovery

  def test(pid) do
    :dbg.start()
    :dbg.tracer()
    :dbg.p(pid, :c)

    ModuleDiscovery.find_live_modules()
    |> callbacks()
    |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)
  end

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  @impl true
  def init(pid) do
    # pid
    # |> ChannelStateScraper.get_used_modules()
    # |> case do
    #   {:ok, modules} ->
    #     Enum.flat_map(modules, &callbacks/1)
    #   {:error, reason} ->
    #     {:stop, reason}
    # end
    # %{live_views: live_view_modules, live_components: live_component_modules} =
    {:ok, pid}
  end

  defp callbacks(%{live_views: live_views, live_components: live_components}) do
    Enum.flat_map(live_views, &live_view_callbacks/1) ++
      Enum.flat_map(live_components, &live_component_callbacks/1)
  end

  defp live_view_callbacks(module) do
    [
      {module, :mount, 3},
      {module, :handle_params, 3},
      {module, :handle_info, 2},
      {module, :handle_call, 3},
      {module, :handle_cast, 2},
      {module, :terminate, 2}
    ] ++ common_callbacks(module)
  end

  def live_component_callbacks(module) do
    [
      {module, :mount, 1},
      {module, :update, 2},
      {module, :update_many, 1}
    ] ++ common_callbacks(module)
  end

  defp common_callbacks(module) do
    [
      {module, :render, 1},
      {module, :handle_event, 3},
      {module, :handle_async, 3}
    ]
  end
end
