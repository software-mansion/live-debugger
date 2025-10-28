defmodule LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo do
  @moduledoc """
  This module provides a struct to represent process information.
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
          # :low | :normal | :high | :max - Process priority level
          priority: :low | :normal | :high | :max,
          # non_neg_integer - Number of reductions executed by the process
          reductions: non_neg_integer(),
          # non_neg_integer (bytes) - Total memory used by the process
          memory: non_neg_integer(),
          # non_neg_integer (bytes) - Total heap size in bytes
          total_heap_size: non_neg_integer(),
          # non_neg_integer (bytes) - Heap size in bytes
          heap_size: non_neg_integer(),
          # non_neg_integer (bytes) - Stack size in bytes
          stack_size: non_neg_integer()
        }

  @word_size :erlang.system_info(:wordsize)

  defstruct initial_call: nil,
            current_function: nil,
            registered_name: [],
            status: :running,
            message_queue_len: 0,
            priority: :normal,
            reductions: 0,
            memory: 0,
            total_heap_size: 0,
            heap_size: 0,
            stack_size: 0

  def new(process_info_keyword_list) when is_list(process_info_keyword_list) do
    struct(__MODULE__, extract_process_info(process_info_keyword_list))
  end

  @spec extract_process_info(keyword()) :: map()
  defp extract_process_info(process_info_keyword_list) do
    info_map = Enum.into(process_info_keyword_list, %{})

    overview = %{
      initial_call: Map.get(info_map, :initial_call),
      current_function: Map.get(info_map, :current_function),
      registered_name: Map.get(info_map, :registered_name, []),
      status: Map.get(info_map, :status, :running),
      message_queue_len: Map.get(info_map, :message_queue_len, 0),
      priority: Map.get(info_map, :priority, :normal),
      reductions: Map.get(info_map, :reductions, 0),
      suspending: Map.get(info_map, :suspending, [])
    }

    memory_gc = %{
      memory: Map.get(info_map, :memory, 0),
      total_heap_size: words_to_bytes(Map.get(info_map, :total_heap_size, 0), @word_size),
      heap_size: words_to_bytes(Map.get(info_map, :heap_size, 0), @word_size),
      stack_size: words_to_bytes(Map.get(info_map, :stack_size, 0), @word_size)
    }

    Map.merge(overview, memory_gc)
  end

  @spec words_to_bytes(term(), pos_integer()) :: non_neg_integer()
  defp words_to_bytes(nil, _word_size), do: 0

  defp words_to_bytes(size, word_size) when is_integer(size) do
    size * word_size
  end

  defp words_to_bytes(size, _word_size), do: size
end
