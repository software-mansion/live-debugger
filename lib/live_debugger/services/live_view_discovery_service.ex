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
  Returns pids of the LiveView processes associated with the given `socket_id` and optional `nested_socket_id`.
  These are unstructured LiveViewProcess structs. Use `merge_live_view_processes/1` to convert them into tree.
  """
  @spec live_view_processes(root_socket_id :: String.t()) :: [LiveViewProcess.t()]
  def live_view_processes(root_socket_id) when is_binary(root_socket_id) do
    lv_processes =
      debugged_live_pids()
      |> pids_to_live_view_processes()

    root_pid = Enum.find_value(lv_processes, &(&1.socket_id == root_socket_id), & &1.pid)

    lv_processes
    |> Enum.filter(fn process ->
      process.root_pid == root_pid
    end)
    |> Enum.map(fn process ->
      %LiveViewProcess{process | root_socket_id: root_socket_id}
    end)
  end

  @doc """
  Returns list of LiveView processes information based on the given pids.
  If omits the processes which states couldn't be fetched.
  """
  @spec pids_to_live_view_processes([pid()]) :: [LiveViewProcess.t()]
  def pids_to_live_view_processes(pids) when is_list(pids) do
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

  @doc """
  Merges the given list of LiveViewProcess into a tree structure.
  """
  @spec merge_live_view_processes([LiveViewProcess.t()]) :: map()
  def merge_live_view_processes(live_view_processes) when is_list(live_view_processes) do
    children_live_view_processes(live_view_processes, & &1.root?)
  end

  @spec merge_live_view_processes([LiveViewProcess.t()], LiveViewProcess.t()) ::
          {LiveViewProcess.t(), map()}
  defp merge_live_view_processes(live_view_processes, parent_process)
       when is_list(live_view_processes) and is_struct(parent_process) do
    children_processes =
      live_view_processes
      |> children_live_view_processes(&(&1.parent_pid == parent_process.pid))
      |> Enum.map(fn {parent, children} ->
        {%LiveViewProcess{parent | root_socket_id: parent_process.root_socket_id}, children}
      end)
      |> Enum.into(%{})

    {parent_process, children_processes}
  end

  @spec children_live_view_processes([LiveViewProcess.t()], (LiveViewProcess.t() -> boolean())) ::
          map()
  defp children_live_view_processes(all_live_view_processes, choose_children_fn) do
    all_live_view_processes
    |> Enum.filter(choose_children_fn)
    |> Enum.map(fn child_process ->
      merge_live_view_processes(all_live_view_processes, child_process)
    end)
    |> Enum.into(%{})
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
