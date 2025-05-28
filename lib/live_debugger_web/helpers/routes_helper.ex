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
    ~p"/pid/#{Parsers.pid_to_string(pid)}"
  end

  @spec window_dashboard(pid :: pid()) :: String.t()
  def window_dashboard(pid) when is_pid(pid) do
    ~p"/transport_pid/#{Parsers.pid_to_string(pid)}"
  end

  @spec error(String.t()) :: String.t()
  def error(error) do
    ~p"/error/#{error}"
  end

  @spec settings() :: String.t()
  def settings(return_to \\ nil)

  def settings(nil) do
    ~p"/settings"
  end

  def settings(return_to) do
    ~p"/settings?return_to=#{return_to}"
  end

  @spec global_traces(pid :: pid()) :: String.t()
  def global_traces(pid) when is_pid(pid) do
    ~p"/pid/#{Parsers.pid_to_string(pid)}/global_traces"
  end
end
