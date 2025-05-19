defmodule LiveDebugger.GenServers.EtsTableServer do
  @moduledoc """
  This gen_server is responsible for managing ETS tables.
  """

  use GenServer

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @ets_table_name :lvdbg_traces

  @type table_refs() :: %{pid() => :ets.table()}

  ## API

  @callback table(pid :: pid()) :: :ets.table()
  @callback delete_table(pid :: pid()) :: :ok

  @doc """
  Returns ETS table reference.
  It creates table if none is associated with given pid
  """
  @spec table(pid :: pid()) :: :ets.table()
  def table(pid) when is_pid(pid), do: impl().table(pid)

  @doc """
  If table for given `pid` exists it deletes it from ETS.
  """
  @spec delete_table(pid :: pid()) :: :ok
  def delete_table(pid) when is_pid(pid), do: impl().delete_table(pid)

  ## GenServer

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def handle_info({:DOWN, _, :process, closed_pid, _}, table_refs) do
    {_, table_refs} = delete_ets_table(closed_pid, table_refs)

    PubSubUtils.process_status_topic()
    |> PubSubUtils.broadcast({:process_status, {:dead, closed_pid}})

    {:noreply, table_refs}
  end

  @impl true
  def handle_call({:get_or_create_table, pid}, _from, table_refs) do
    case Map.get(table_refs, pid) do
      nil ->
        ref = create_ets_table()
        Process.monitor(pid)
        {:reply, ref, Map.put(table_refs, pid, ref)}

      ref ->
        {:reply, ref, table_refs}
    end
  end

  @impl true
  def handle_call({:delete_table, pid}, _from, table_refs) do
    {_, table_refs} = delete_ets_table(pid, table_refs)
    {:reply, :ok, table_refs}
  end

  defp impl() do
    Application.get_env(:live_debugger, :ets_table_server, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.GenServers.EtsTableServer
    @server_module LiveDebugger.GenServers.EtsTableServer

    @impl true
    def table(pid) do
      GenServer.call(@server_module, {:get_or_create_table, pid}, 1000)
    end

    @impl true
    def delete_table(pid) do
      GenServer.call(@server_module, {:delete_table, pid}, 1000)
    end
  end

  @spec create_ets_table() :: :ets.table()
  defp create_ets_table() do
    :ets.new(@ets_table_name, [:ordered_set, :public])
  end

  @spec delete_ets_table(pid(), table_refs()) :: {boolean(), table_refs()}
  defp delete_ets_table(pid, table_refs) do
    case Map.pop(table_refs, pid) do
      {nil, table_refs} ->
        {false, table_refs}

      {ref, updated_table_refs} ->
        :ets.delete(ref)
        {true, updated_table_refs}
    end
  end
end
