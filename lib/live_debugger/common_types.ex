defmodule LiveDebugger.CommonTypes do
  @moduledoc """
  This module provides types used in the LiveDebugger application.
  """

  @typedoc """
  Type for state of a channel that hosts a LiveView.
  """
  @type channel_state() :: %{
          socket: Phoenix.LiveView.Socket.t(),
          components: list(map())
        }

  @type cid() :: %Phoenix.LiveComponent.CID{cid: integer()}
end
