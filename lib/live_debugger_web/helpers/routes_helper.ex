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

  def channel_dashboard(pid, cid) do
    pid =
      cond do
        is_pid(pid) -> Parsers.pid_to_string(pid)
        is_binary(pid) -> pid
      end

    cid =
      case cid do
        %Phoenix.LiveComponent.CID{} -> Parsers.cid_to_string(cid)
        cid when is_binary(cid) -> cid
      end

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
