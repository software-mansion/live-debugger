defmodule LiveDebuggerRefactor.API.TracesStorage do
  @moduledoc """
  API for managing traces storage. In order to properly use invoke `init/0` at the start of application.
  It uses Erlang's ETS (Erlang Term Storage).
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes

  @type ets_continuation() :: term()
  @typedoc """
  Pid is used to store mapping to table references.
  It identifies ETS tables managed by EtsTableServer.
  """
  @type ets_table_id() :: pid()
  @type table_identifier() :: ets_table_id() | reference()

  @callback init() :: :ok
  @callback insert(Trace.t()) :: true
  @callback insert(table_ref :: reference(), Trace.t()) :: true
  @callback get(table_identifier(), trace_id :: integer()) :: Trace.t() | nil
  @callback get(table_identifier(), opts :: keyword()) ::
              {[Trace.t()], ets_continuation()} | :end_of_table
  @callback clear(table_identifier(), node_id :: pid() | CommonTypes.cid() | nil) :: true
  @callback clear(table_identifier()) :: true
  @callback get_table(ets_table_id()) :: reference() | nil
  @callback get_all_tables() :: [reference()]

  defguard is_table_identifier(id) when is_pid(id) or is_reference(id)

  @doc """
  Initializes ets table.
  It should be called when application starts.
  """
  @spec init() :: :ok
  def init(), do: impl().init()

  @doc """
  Inserts a new trace into the storage.
  """
  @spec insert(Trace.t()) :: true
  def insert(%Trace{} = trace) do
    impl().insert(trace)
  end

  @spec insert(table_ref :: reference(), Trace.t()) :: true
  def insert(table_ref, %Trace{} = trace) when is_reference(table_ref) do
    impl().insert(table_ref, trace)
  end

  @doc """
  Gets a trace of a process from the storage by `id`.
  """
  @spec get(table_identifier(), trace_id :: integer()) :: Trace.t() | nil
  def get(table_id, trace_id) when is_table_identifier(table_id) and is_integer(trace_id) do
    impl().get(table_id, trace_id)
  end

  @doc """
  Returns traces of a process with optional filters.

  ## Options
    * `:node_id` - PID or CID to filter traces by
    * `:limit` - Maximum number of traces to return (default: 100)
    * `:cont` - Used to get next page of items in the following queries
    * `:functions` - List of function names to filter traces by e.g ["handle_info/2", "render/1"]
    * `:search_query` - String to filter traces by, performs a case-sensitive substring search on the entire Trace struct
  """
  @spec get(table_identifier(), opts :: keyword()) ::
          {[Trace.t()], ets_continuation()} | :end_of_table
  def get(table_id, opts) when is_table_identifier(table_id) and is_list(opts) do
    impl().get(table_id, opts)
  end

  @doc """
  Deletes traces for given node_id. If node_id is nil, it deletes all traces for a given table.

  * `node_id` - PID or CID which identifies node. If nil, it deletes all traces for a given table.
  """
  @spec clear(table_identifier(), node_id :: pid() | CommonTypes.cid() | nil) :: true
  def clear(table_id, node_id) when is_table_identifier(table_id) do
    impl().clear(table_id, node_id)
  end

  @doc """
  Deletes all traces for a given table.
  """
  @spec clear(table_identifier()) :: true
  def clear(table_id) when is_table_identifier(table_id) do
    impl().clear(table_id)
  end

  @doc """
  Returns table reference for a given process
  """
  @spec get_table(ets_table_id()) :: reference() | nil
  def get_table(pid) when is_pid(pid) do
    impl().get_table(pid)
  end

  @doc """
  Returns all table references
  """
  @spec get_all_tables() :: [reference()]
  def get_all_tables() do
    impl().get_all_tables()
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_traces_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebuggerRefactor.API.TracesStorage

    alias Phoenix.LiveComponent.CID

    @default_limit 100

    @type ets_elem() :: {integer(), Trace.t()}
  end
end
