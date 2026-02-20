defmodule LiveDebugger.Client.Socket do
  @moduledoc false

  use Phoenix.Socket

  channel("client:*", LiveDebugger.Client.Channel)

  @impl true
  def connect(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
