defmodule LiveDebugger.Utils.Callbacks do
  @moduledoc """
  This module provides functions to generate a list of callbacks for LiveViews and LiveComponents.
  """

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
  Generates a list of callbacks for LiveViews in form of {module, callback, arity}.
  Accept a single module or a list of modules.
  """
  @spec live_view_callbacks(module() | [module()]) :: [mfa()]
  def live_view_callbacks(modules) when is_list(modules) do
    Enum.flat_map(modules, &live_view_callbacks/1)
  end

  def live_view_callbacks(module) when is_atom(module) do
    Enum.map(@live_view_callbacks, fn {callback, arity} -> {module, callback, arity} end)
  end

  @doc """
  Generates a list of callbacks for LiveComponents in form of {module, callback, arity}.
  Accepts a single module or a list of modules.
  """
  @spec live_component_callbacks(module() | [module()]) :: [mfa()]
  def live_component_callbacks(modules) when is_list(modules) do
    Enum.flat_map(modules, &live_component_callbacks/1)
  end

  def live_component_callbacks(module) when is_atom(module) do
    Enum.map(@live_component_callbacks, fn {callback, arity} -> {module, callback, arity} end)
  end
end
