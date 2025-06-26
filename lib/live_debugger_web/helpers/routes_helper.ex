defmodule LiveDebuggerWeb.Helpers.RoutesHelper do
  @moduledoc """
  Helper module to generate url routes for the LiveDebugger application.
  """

  use Phoenix.VerifiedRoutes, endpoint: LiveDebuggerWeb.Endpoint, router: LiveDebuggerWeb.Router

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Utils.Parsers

  @spec live_views_dashboard() :: String.t()
  def live_views_dashboard() do
    ~p"/"
  end

  @spec channel_dashboard(pid :: pid() | String.t(), cid :: CommonTypes.cid() | String.t() | nil) ::
          String.t()
  def channel_dashboard(pid, nil) do
    channel_dashboard(pid)
  end

  def channel_dashboard(pid, %Phoenix.LiveComponent.CID{} = cid) when is_pid(pid) do
    pid = Parsers.pid_to_string(pid)
    cid = Parsers.cid_to_string(cid)

    channel_dashboard(pid, cid)
  end

  def channel_dashboard(pid, %Phoenix.LiveComponent.CID{} = cid) when is_binary(pid) do
    cid = Parsers.cid_to_string(cid)
    channel_dashboard(pid, cid)
  end

  def channel_dashboard(pid, cid) when is_pid(pid) and is_binary(cid) do
    pid = Parsers.pid_to_string(pid)
    channel_dashboard(pid, cid)
  end

  def channel_dashboard(pid, cid) when is_binary(pid) and is_binary(cid) do
    ~p"/pid/#{pid}?node_id=#{cid}"
  end

  @spec channel_dashboard(pid :: pid() | String.t()) :: String.t()
  def channel_dashboard(pid) when is_pid(pid) do
    pid
    |> Parsers.pid_to_string()
    |> channel_dashboard()
  end

  def channel_dashboard(pid) when is_binary(pid) do
    ~p"/pid/#{pid}"
  end

  @spec global_traces(pid :: pid() | String.t()) :: String.t()
  def global_traces(pid) when is_pid(pid) do
    pid
    |> Parsers.pid_to_string()
    |> global_traces()
  end

  def global_traces(pid) when is_binary(pid) do
    ~p"/pid/#{pid}/global_traces"
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
end
