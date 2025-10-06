defmodule LiveDebugger.API.ProcessInfo do
  @moduledoc """
  Elixir equivalent of the Erlang observer_procinfo:process_info_fields/2 function.

  Provides comprehensive process information including overview, associated processes,
  and memory/garbage collection details.
  """

  @type t :: %__MODULE__{
          # {module, function, arity} - The initial function call that started the process
          initial_call: {module(), atom(), non_neg_integer()} | nil,
          # {module, function, arity} - The current function being executed
          current_function: {module(), atom(), non_neg_integer()} | nil,
          # atom | [] - The registered name of the process, or [] if not registered
          registered_name: atom() | [],
          # :running | :waiting | :suspended | :garbage_collecting - Current process status
          status: :running | :waiting | :suspended | :garbage_collecting,
          # non_neg_integer - Number of messages in the process mailbox
          message_queue_len: non_neg_integer(),
          # pid - The group leader process
          group_leader: pid() | nil,
          # :low | :normal | :high | :max - Process priority level
          priority: :low | :normal | :high | :max,
          # boolean - Whether the process traps exits from linked processes
          trap_exit: boolean(),
          # non_neg_integer - Number of reductions executed by the process
          reductions: non_neg_integer(),
          # boolean - Whether last call optimization is enabled
          last_calls: boolean(),
          # non_neg_integer - Trace level for the process
          trace: non_neg_integer(),
          # [term()] - Sequential trace token for the process
          sequential_trace_token: [term()],
          # atom - The error handler module for the process
          error_handler: atom() | nil,

          # [pid()] - List of processes linked to this process
          links: [pid()],
          # [pid()] - List of processes/ports this process is monitoring
          monitors: [pid()],
          # [pid()] - List of processes monitoring this process
          monitored_by: [pid()],
          # [pid()] - List of processes this process is suspending
          suspending: [pid()],

          # Memory and Garbage Collection section
          # non_neg_integer (bytes) - Total memory used by the process
          memory: non_neg_integer(),
          # non_neg_integer (bytes) - Total heap size in bytes
          total_heap_size: non_neg_integer(),
          # non_neg_integer (bytes) - Heap size in bytes
          heap_size: non_neg_integer(),
          # non_neg_integer (bytes) - Stack size in bytes
          stack_size: non_neg_integer(),
          # non_neg_integer (bytes) - Minimum heap size for GC in bytes
          gc_min_heap_size: non_neg_integer(),
          # non_neg_integer - Number of generational GCs before a full sweep
          gc_fullsweep_after: non_neg_integer()
        }

  @type process_info_result :: {:ok, t()} | {:error, :process_undefined | :invalid_pid}

  defstruct initial_call: nil,
            current_function: nil,
            registered_name: [],
            status: :running,
            message_queue_len: 0,
            group_leader: nil,
            priority: :normal,
            trap_exit: false,
            reductions: 0,
            last_calls: false,
            trace: 0,
            suspending: [],
            sequential_trace_token: [],
            error_handler: nil,
            links: [],
            monitors: [],
            monitored_by: [],
            memory: 0,
            total_heap_size: 0,
            heap_size: 0,
            stack_size: 0,
            gc_min_heap_size: 0,
            gc_fullsweep_after: 0

  @doc """
  Gets process information for a given PID and returns a ProcessInfo struct.

  ## Parameters
  - `pid` - The process ID to get information for

  ## Returns
  - `{:ok, %ProcessInfo{}}` - Success with process information struct
  - `{:error, :process_undefined}` - Process doesn't exist or is invalid
  - `{:error, :invalid_pid}` - Invalid PID format

  ## Examples

      iex> ProcessInfo.get_process_info(self())
      {:ok, %ProcessInfo{status: :running, ...}}

      iex> ProcessInfo.get_process_info(:non_existent)
      {:error, :process_undefined}
  """
  @spec get_process_info(pid()) :: process_info_result()
  def get_process_info(pid) do
    word_size = :erlang.system_info(:wordsize)

    try do
      case :erlang.process_info(pid, item_list()) do
        raw_info when is_list(raw_info) ->
          {:ok, struct(ProcessInfo, extract_process_info(raw_info, word_size))}

        _ ->
          {:error, :process_undefined}
      end
    rescue
      ArgumentError -> {:error, :invalid_pid}
    end
  end

  # Helper function to extract and format process information
  @spec extract_process_info(list(), pos_integer()) :: map()
  defp extract_process_info(raw_info, word_size) do
    # Convert raw info to a map for easier access
    info_map = Enum.into(raw_info, %{})

    # Extract overview information
    overview = %{
      initial_call: Map.get(info_map, :initial_call),
      current_function: Map.get(info_map, :current_function),
      registered_name: Map.get(info_map, :registered_name, []),
      status: Map.get(info_map, :status, :running),
      message_queue_len: Map.get(info_map, :message_queue_len, 0),
      group_leader: Map.get(info_map, :group_leader),
      priority: Map.get(info_map, :priority, :normal),
      trap_exit: Map.get(info_map, :trap_exit, false),
      reductions: Map.get(info_map, :reductions, 0),
      last_calls: Map.get(info_map, :last_calls, false),
      trace: Map.get(info_map, :trace, 0),
      suspending: Map.get(info_map, :suspending, []),
      sequential_trace_token: Map.get(info_map, :sequential_trace_token, []),
      error_handler: Map.get(info_map, :error_handler)
    }

    # Extract scroll boxes information
    scroll_boxes = %{
      links: Map.get(info_map, :links, []),
      monitors: filter_monitor_info(Map.get(info_map, :monitors, [])),
      monitored_by: Map.get(info_map, :monitored_by, [])
    }

    # Extract memory and GC information
    memory_gc = %{
      memory: Map.get(info_map, :memory, 0),
      total_heap_size: words_to_bytes(Map.get(info_map, :total_heap_size, 0), word_size),
      heap_size: words_to_bytes(Map.get(info_map, :heap_size, 0), word_size),
      stack_size: words_to_bytes(Map.get(info_map, :stack_size, 0), word_size),
      gc_min_heap_size: get_gc_info_bytes(info_map, :min_heap_size, word_size),
      gc_fullsweep_after: get_gc_info(info_map, :fullsweep_after, word_size)
    }

    # Merge all sections
    Map.merge(overview, Map.merge(scroll_boxes, memory_gc))
  end

  # List of items to retrieve from process_info
  @spec item_list() :: [atom()]
  defp item_list do
    [
      :current_function,
      :error_handler,
      :garbage_collection,
      :group_leader,
      :heap_size,
      :initial_call,
      :last_calls,
      :links,
      :memory,
      :message_queue_len,
      :monitored_by,
      :monitors,
      :priority,
      :reductions,
      :registered_name,
      :sequential_trace_token,
      :stack_size,
      :status,
      :suspending,
      :total_heap_size,
      :trace,
      :trap_exit
    ]
  end

  # Filter monitor information to extract just the IDs
  @spec filter_monitor_info(list()) :: [pid()]
  defp filter_monitor_info(monitors) when is_list(monitors) do
    Enum.map(monitors, fn {_type, id} -> id end)
  end

  defp filter_monitor_info(_), do: []

  # Get garbage collection information
  @spec get_gc_info(map(), atom(), pos_integer()) :: non_neg_integer()
  defp get_gc_info(info_map, key, _word_size) do
    case Map.get(info_map, :garbage_collection) do
      nil ->
        0

      gc_info when is_list(gc_info) ->
        Keyword.get(gc_info, key, 0)
    end
  end

  # Get garbage collection information in bytes
  @spec get_gc_info_bytes(map(), atom(), pos_integer()) :: non_neg_integer()
  defp get_gc_info_bytes(info_map, key, word_size) do
    case Map.get(info_map, :garbage_collection) do
      nil ->
        0

      gc_info when is_list(gc_info) ->
        case Keyword.get(gc_info, key, 0) do
          value when key == :min_heap_size -> words_to_bytes(value, word_size)
          value -> value
        end
    end
  end

  # Convert word size to bytes
  @spec words_to_bytes(term(), pos_integer()) :: non_neg_integer()
  defp words_to_bytes(nil, _word_size), do: 0

  defp words_to_bytes(size, word_size) when is_integer(size) do
    size * word_size
  end

  defp words_to_bytes(size, _word_size), do: size
end
