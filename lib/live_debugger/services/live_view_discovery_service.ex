defmodule LiveDebugger.Services.LiveViewDiscoveryService do
  @moduledoc """
  This module provides functions that discovers LiveView processes in the debugged application.
  """
  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Structs.LiveViewProcess

  @doc """
  Returns pids of all LiveView processes in the debugged application.
  """
  @spec debugged_live_pids() :: [pid()]
  def debugged_live_pids() do
    all_live_pids()
    |> Enum.reject(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Returns pids of all LiveView processes in the LiveDebugger application
  """
  @spec debugger_live_pids() :: [pid()]
  def debugger_live_pids() do
    all_live_pids()
    |> Enum.filter(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Returns pids of the LiveView processes associated with the given `socket_id`.
  First element of the list is the root process.
  If the list is empty, it means that there is no LiveView process associated with the given `socket_id`.
  """
  @spec live_pids(socket_id :: String.t()) :: [pid()]
  def live_pids(socket_id) do
    all_lv_processes = debugged_live_pids() |> live_view_processes()

    socket_process_pid =
      all_lv_processes
      |> Enum.find(fn lv_process -> lv_process.socket_id == socket_id end)
      |> case do
        %LiveViewProcess{pid: pid} -> pid
        nil -> []
      end

    with pid when is_pid(pid) <- socket_process_pid do
      child_pids =
        all_lv_processes
        |> Enum.filter(fn lv_process ->
          (lv_process.root_pid == pid || lv_process.parent_pid == pid) && lv_process.pid != pid
        end)
        |> Enum.map(& &1.pid)

      [pid | child_pids]
    end
  end

  @doc """
  Returns list of LiveView processes information based on the given pids.
  If omits the processes which states couldn't be fetched.
  """
  @spec live_view_processes([pid()]) :: [LiveViewProcess.t()]
  def live_view_processes(pids) do
    pids
    |> Enum.map(fn pid ->
      case ProcessService.state(pid) do
        {:ok, %{socket: socket}} ->
          LiveDebugger.Structs.LiveViewProcess.new(pid, socket)

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @spec all_live_pids() :: [{pid(), mfa()}]
  defp all_live_pids() do
    ProcessService.list()
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(&{&1, ProcessService.initial_call(&1)})
    |> Enum.filter(fn {_, initial_call} -> liveview?(initial_call) end)
  end

  @spec liveview?(mfa() | nil | {}) :: boolean()
  defp liveview?(initial_call) when initial_call not in [nil, {}] do
    elem(initial_call, 1) == :mount
  end

  defp liveview?(_), do: false

  @spec debugger?(mfa() | nil | {}) :: boolean()
  defp debugger?(initial_call) when initial_call not in [nil, {}] do
    initial_call
    |> elem(0)
    |> Atom.to_string()
    |> String.starts_with?("Elixir.LiveDebugger.")
  end

  defp debugger?(_), do: false
end
