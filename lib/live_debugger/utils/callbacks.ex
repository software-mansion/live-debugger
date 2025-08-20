defmodule LiveDebugger.Utils.Callbacks do
  @moduledoc """
  This module provides list of callbacks for LiveViews and LiveComponents in form of {callback, arity}.
  Callbacks are returned in order of their "importance".
  """

  @type fa() :: {atom(), non_neg_integer()}

  @doc """
  Returns a list of callbacks for LiveViews.
  """
  @spec live_view_callbacks() :: [fa()]
  def live_view_callbacks() do
    [
      {:mount, 3},
      {:handle_params, 3},
      {:render, 1},
      {:handle_event, 3},
      {:handle_async, 3},
      {:handle_info, 2},
      {:handle_call, 3},
      {:handle_cast, 2},
      {:terminate, 2}
    ]
  end

  @doc """
  Returns a list of callbacks for LiveComponents.
  """
  @spec live_component_callbacks() :: [fa()]
  def live_component_callbacks() do
    [
      {:mount, 1},
      {:update, 2},
      {:update_many, 1},
      {:render, 1},
      {:handle_event, 3},
      {:handle_async, 3}
    ]
  end

  @doc """
  Returns a list of all callbacks for LiveViews and LiveComponents.
  """
  @spec all_callbacks() :: [fa()]
  def all_callbacks() do
    [
      {:mount, 3},
      {:mount, 1},
      {:handle_params, 3},
      {:update, 2},
      {:update_many, 1},
      {:render, 1},
      {:handle_event, 3},
      {:handle_async, 3},
      {:handle_info, 2},
      {:handle_call, 3},
      {:handle_cast, 2},
      {:terminate, 2}
    ]
  end
end
