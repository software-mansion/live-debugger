defmodule LiveDebugger.GenServers.StateServer do
  @moduledoc """
  This gen_server is responsible for storing the state of the application.
  It collects state when `render` or `delete_component` callbacks are traced.
  It uses named ETS table to store the state of the LiveView channel process.
  When process dies, it removes the state from the table.
  """

  use GenServer

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.Trace

  @ets_table_name :lvdbg_states

  @callback get(pid :: pid()) :: {:ok, CommonTypes.channel_state()} | {:error, term()}

  @doc """
  Returns previously stored state of the LiveView channel process identified by `pid`.
  If the state is not found, it returns `{:error, :not_found}`.
  """
  @spec get(pid :: pid()) :: {:ok, CommonTypes.channel_state()} | {:error, term()}
  def get(pid) when is_pid(pid) do
    impl().get(pid)
  end

  @doc false
  @spec ets_table_name() :: atom()
  def ets_table_name(), do: @ets_table_name

  @doc false
  def record_id(pid), do: "#{inspect(pid)}"

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    :ets.new(@ets_table_name, [:named_table, :public, :ordered_set])

    PubSubUtils.node_rendered()
    |> PubSubUtils.subscribe!()

    PubSubUtils.component_deleted_topic()
    |> PubSubUtils.subscribe!()

    PubSubUtils.process_status_topic()
    |> PubSubUtils.subscribe!()

    {:ok, []}
  end

  @impl true
  def handle_info({:component_deleted, trace}, state) do
    save_state(trace)

    {:noreply, state}
  end

  def handle_info({:render_trace, trace}, state) do
    save_state(trace)

    {:noreply, state}
  end

  def handle_info({:process_status, {:dead, pid}}, state) do
    :ets.delete(@ets_table_name, record_id(pid))

    {:noreply, state}
  end

  defp save_state(%Trace{pid: pid} = trace) do
    with {:ok, channel_state} <- ProcessService.state(pid) do
      record_id = record_id(pid)
      :ets.insert(@ets_table_name, {record_id, channel_state})

      publish_state_changed(trace, channel_state)
    end
  end

  defp publish_state_changed(%Trace{} = trace, channel_state) do
    socket_id = trace.socket_id
    transport_pid = trace.transport_pid
    node_id = trace.cid || trace.pid

    PubSubUtils.state_changed_topic(socket_id, transport_pid, node_id)
    |> PubSubUtils.broadcast({:state_changed, channel_state, trace})

    PubSubUtils.state_changed_topic(socket_id, transport_pid)
    |> PubSubUtils.broadcast({:state_changed, channel_state, trace})
  end

  defp impl() do
    Application.get_env(:live_debugger, :state_server, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false

    @behaviour LiveDebugger.GenServers.StateServer
    @server_module LiveDebugger.GenServers.StateServer

    def get(pid) do
      case :ets.lookup(@server_module.ets_table_name(), @server_module.record_id(pid)) do
        [{_, channel_state}] -> {:ok, channel_state}
        [] -> {:error, :not_found}
      end
    end
  end
end
