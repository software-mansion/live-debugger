defmodule LiveDebugger.Services.SuccessorDiscoverer.Queries.Successor do
  @moduledoc """
  Queries for finding a successor of LiveView process.
  """

  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.Structs.LvProcess

  @spec find_successor(lv_process :: LvProcess.t(), new_socket_id :: String.t() | nil) ::
          LvProcess.t() | nil
  def find_successor(lv_process, new_socket_id) do
    with lv_processes <- LiveViewDiscovery.debugged_lv_processes(),
         nil <- find_successor_by_transport_pid(lv_processes, lv_process) do
      find_successor_using_state(lv_processes, new_socket_id)
    else
      successor -> successor
    end
  end

  # It finds a successor of LiveView process within the same transport pid.
  # If LiveViews have the same transport pid, it means that they are hosted by the same WebSocket connection.
  # When LiveViews are hosted by the same WebSocket connection it means that they are displayed in the same browser tab.
  defp find_successor_by_transport_pid(lv_processes, lv_process) do
    lv_processes
    |> Enum.filter(&(&1.transport_pid == lv_process.transport_pid))
    |> find_successor_by_priority()
  end

  defp find_successor_by_priority(transport_processes) do
    find_first_match([
      # Priority 1: Find a non-nested, non-embedded process with matching transport_pid
      fn -> find_non_nested_non_embedded(transport_processes) end,
      # Priority 2: Use single process with matching transport_pid if it exists
      fn -> find_single_process(transport_processes) end
    ])
  end

  defp find_first_match(functions) do
    Enum.reduce_while(functions, nil, fn fun, _acc ->
      case fun.() do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end

  defp find_non_nested_non_embedded(processes) do
    Enum.find(processes, &(not &1.nested? and not &1.embedded?))
  end

  defp find_single_process(processes) do
    if length(processes) == 1, do: List.first(processes), else: nil
  end

  # It finds a successor based on new_socket_id
  defp find_successor_using_state(lv_processes, new_socket_id) when not is_nil(new_socket_id) do
    lv_processes
    |> Enum.filter(&(&1.socket_id == new_socket_id))
    |> case do
      [successor] -> successor
      _ -> nil
    end
  end

  defp find_successor_using_state(_, _), do: nil
end
