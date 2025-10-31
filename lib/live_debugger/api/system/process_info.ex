defmodule LiveDebugger.API.System.ProcessInfo do
  @moduledoc """
  This module provides wrappers for system functions that queries process information.
  """

  @callback get_info(pid :: pid()) :: {:ok, keyword()} | {:error, term()}

  @doc """
  Wrapper for `:erlang.process_info/1`.
  Returns a keyword list of data items for the given process.
  """

  @spec get_info(pid :: pid()) :: {:ok, keyword()} | {:error, term()}
  def get_info(pid) when is_pid(pid) do
    impl().get_info(pid)
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_process_info,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.System.ProcessInfo

    @items_list ~w(
      current_function
      garbage_collection
      heap_size
      initial_call
      links
      memory
      message_queue_len
      monitored_by
      monitors
      priority
      reductions
      registered_name
      stack_size
      status
      suspending
      total_heap_size
    )a

    @impl true
    def get_info(pid) when is_pid(pid) do
      pid
      |> :erlang.process_info(@items_list)
      |> case do
        info when is_list(info) -> {:ok, info}
        _ -> {:error, "Could not find process"}
      end
    end
  end
end
