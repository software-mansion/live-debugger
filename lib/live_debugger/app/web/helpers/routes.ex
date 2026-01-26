defmodule LiveDebugger.App.Web.Helpers.Routes do
  @moduledoc """
  Helper module for generating verified routes in the LiveDebugger application.
  See `Phoenix.VerifiedRoutes` for more details.
  """

  use Phoenix.VerifiedRoutes,
    endpoint: LiveDebugger.App.Web.Endpoint,
    router: LiveDebugger.App.Web.Router

  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.CommonTypes

  @spec discovery() :: String.t()
  def discovery() do
    ~p"/"
  end

  @spec debugger(pid :: pid() | String.t(), live_action :: atom()) :: String.t()
  def debugger(pid, :node_inspector), do: debugger_node_inspector(pid)
  def debugger(pid, :global_traces), do: debugger_global_traces(pid)
  def debugger(pid, :resources), do: debugger_resources(pid)

  @spec debugger_node_inspector(
          pid :: pid() | String.t(),
          cid :: CommonTypes.cid() | String.t() | nil,
          opts :: keyword()
        ) ::
          String.t()

  def debugger_node_inspector(pid, cid, opts) do
    pid_str =
      cond do
        is_pid(pid) -> Parsers.pid_to_string(pid)
        is_binary(pid) -> pid
      end

    params =
      if cid do
        cid_str =
          case cid do
            %Phoenix.LiveComponent.CID{} -> Parsers.cid_to_string(cid)
            cid when is_binary(cid) -> cid
          end

        [node_id: cid_str] ++ opts
      else
        opts
      end

    ~p"/pid/#{pid_str}?#{params}"
  end

  @spec debugger_node_inspector(pid(), keyword()) :: String.t()
  def debugger_node_inspector(pid, opts) when is_list(opts) do
    debugger_node_inspector(pid, nil, opts)
  end

  @spec debugger_node_inspector(pid(), CommonTypes.cid() | String.t() | nil) :: String.t()
  def debugger_node_inspector(pid, cid) do
    debugger_node_inspector(pid, cid, [])
  end

  @spec debugger_node_inspector(pid()) :: String.t()
  def debugger_node_inspector(pid) do
    debugger_node_inspector(pid, nil, [])
  end

  @spec debugger_global_traces(pid :: pid() | String.t()) :: String.t()
  def debugger_global_traces(pid) when is_pid(pid) do
    pid
    |> Parsers.pid_to_string()
    |> debugger_global_traces()
  end

  def debugger_global_traces(pid) when is_binary(pid) do
    ~p"/pid/#{pid}/global_traces"
  end

  @spec debugger_resources(pid :: pid() | String.t()) :: String.t()
  def debugger_resources(pid) when is_pid(pid) do
    pid
    |> Parsers.pid_to_string()
    |> debugger_resources()
  end

  def debugger_resources(pid) when is_binary(pid) do
    ~p"/pid/#{pid}/resources"
  end

  @spec error(String.t()) :: String.t()
  def error(error) do
    ~p"/error/#{error}"
  end

  @spec settings(return_to :: String.t() | nil) :: String.t()
  def settings(return_to \\ nil)

  def settings(nil) do
    ~p"/settings"
  end

  def settings(return_to) do
    ~p"/settings?return_to=#{return_to}"
  end
end
