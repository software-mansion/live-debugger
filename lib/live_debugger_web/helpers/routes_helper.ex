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

  @spec channel_dashboard(pid :: pid(), window_id :: String.t() | nil) :: String.t()
  def channel_dashboard(pid, window_id \\ nil)

  def channel_dashboard(pid, nil) do
    ~p"/pid/#{Parsers.pid_to_string(pid)}"
  end

  def channel_dashboard(pid, window_id) do
    ~p"/pid/#{Parsers.pid_to_string(pid)}?window_id=#{window_id}"
  end

  def redirect(window_id, socket_id) do
    ~p"/redirect/#{socket_id}?window_id=#{window_id}"
  end

  @spec error(String.t()) :: String.t()
  def error(error) do
    ~p"/error/#{error}"
  end
end
