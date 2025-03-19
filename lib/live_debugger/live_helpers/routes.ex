defmodule LiveDebugger.LiveHelpers.Routes do
  @moduledoc """
  Helper module to generate url routes for the LiveDebugger application.
  """

  use Phoenix.VerifiedRoutes, endpoint: LiveDebugger.Endpoint, router: LiveDebugger.Router

  alias LiveDebugger.Utils.Parsers

  @spec live_views_dashboard() :: String.t()
  def live_views_dashboard() do
    ~p"/"
  end

  @spec channel_dashboard(socket_id :: String.t(), transport_pid :: pid() | String.t() | nil) ::
          String.t()
  def channel_dashboard(socket_id, transport_pid \\ nil)

  def channel_dashboard(socket_id, nil) when is_binary(socket_id) do
    ~p"/transport_pid/#{socket_id}"
  end

  def channel_dashboard(socket_id, transport_pid)
      when is_binary(socket_id) and is_pid(transport_pid) do
    transport_pid = Parsers.pid_to_string(transport_pid)
    channel_dashboard(socket_id, transport_pid)
  end

  def channel_dashboard(socket_id, transport_pid)
      when is_binary(socket_id) and is_binary(transport_pid) do
    ~p"/#{transport_pid}/#{socket_id}"
  end
end
