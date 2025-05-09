defmodule LiveDebuggerWeb.Helpers.RoutesHelper do
  @moduledoc """
  Helper module to generate url routes for the LiveDebugger application.
  """

  use Phoenix.VerifiedRoutes, endpoint: LiveDebuggerWeb.Endpoint, router: LiveDebuggerWeb.Router

  alias LiveDebugger.Utils.Parsers

  @spec live_views_dashboard() :: String.t()
  def live_views_dashboard() do
    ~p"/"
  end

  @spec channel_dashboard(pid :: pid()) :: String.t()
  def channel_dashboard(pid) when is_pid(pid) do
    ~p"/#{Parsers.pid_to_string(pid)}"
  end
end
