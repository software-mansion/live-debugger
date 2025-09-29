defmodule LiveDebugger.Services.CallbackTracer.Actions.State do
  @moduledoc """
  Actions responsible for saving LiveView process' state.
  """

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Structs.Trace

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

  @doc """
  It checks if the trace is state changing and if so, it saves the state.
  """
  @spec maybe_save_state!(Trace.t()) :: :ok
  def maybe_save_state!(%Trace{pid: pid, function: :render, type: :return_from}) do
    do_save_state!(pid)
  end

  def maybe_save_state!(%Trace{pid: pid, function: function, args: args})
      when function in [:mount, :handle_params] do
    do_save_state!(pid, args)
  end

  def maybe_save_state!(%Trace{pid: pid, function: :delete_component, type: :call}) do
    do_save_state!(pid)
  end

  def maybe_save_state!(_), do: :ok

  defp do_save_state!(pid) do
    with {:ok, lv_state} <- LiveViewDebug.liveview_state(pid) do
      StatesStorage.save!(lv_state)
      Bus.broadcast_state!(%StateChanged{pid: pid}, pid)
      :ok
    end
  end

  defp do_save_state!(pid, args) do
    StatesStorage.save!(%LvState{pid: pid, socket: List.last(args)})
    Bus.broadcast_state!(%StateChanged{pid: pid}, pid)
    :ok
  end
end
