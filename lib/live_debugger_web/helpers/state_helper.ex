defmodule LiveDebuggerWeb.Helpers.StateHelper do
  @moduledoc """
  This module has helper functions for managing state
  """
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Services.ChannelService

  @doc """
  Fetches state using ChannelService when no state is passed
  """
  @spec maybe_get_state(pid :: pid(), channel_state :: CommonTypes.channel_state() | nil) ::
          {:ok, CommonTypes.channel_state()} | {:error, term()}
  def maybe_get_state(pid, channel_state \\ nil) when is_pid(pid) do
    if is_nil(channel_state) do
      ChannelService.state(pid)
    else
      {:ok, channel_state}
    end
  end
end
