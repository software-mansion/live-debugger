defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Assigns.Filters do
  @moduledoc """
  Functions for assigning filters to the socket.
  """

  import Phoenix.Component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  @doc """
  Assigns filters as `:current_filters`.
  """
  def assign_current_filters(socket, filters) do
    assign(socket, :current_filters, filters)
  end

  @doc """
  Assigns default filters as `:current_filters`.
  """
  def assign_current_filters(%{assigns: %{node_id: node_id}} = socket) do
    assign(socket, :current_filters, FiltersHelpers.default_filters(node_id))
  end
end
