defmodule LiveDebugger.Utils.Callbacks do
  alias LiveDebugger.Services.ModuleDiscovery

  @common_callbacks [
    {:render, 1},
    {:handle_event, 3},
    {:handle_async, 3}
  ]

  @live_view_callbacks [
                         {:mount, 3},
                         {:handle_params, 3},
                         {:handle_info, 2},
                         {:handle_call, 3},
                         {:handle_cast, 2},
                         {:terminate, 2}
                       ] ++ @common_callbacks

  @live_component_callbacks [
                              {:mount, 1},
                              {:update, 2},
                              {:update_many, 1}
                            ] ++ @common_callbacks

  @doc """
  Generates a list of callbacks for LiveViews and LiveComponents in form of MFA for the given module.
  """

  @spec tracing_callbacks(ModuleDiscovery.live_modules()) :: [{module(), atom(), integer()}]
  def tracing_callbacks(%{live_views: live_views, live_components: live_components}) do
    Enum.flat_map(live_views, &live_view_callbacks/1) ++
      Enum.flat_map(live_components, &live_component_callbacks/1)
  end

  defp live_view_callbacks(module) do
    Enum.map(@live_view_callbacks, fn {callback, arity} -> {module, callback, arity} end)
  end

  defp live_component_callbacks(module) do
    Enum.map(@live_component_callbacks, fn {callback, arity} -> {module, callback, arity} end)
  end
end
