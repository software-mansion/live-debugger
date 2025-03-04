defmodule LiveDebugger.Utils do
  @moduledoc false

  def nested?(socket_id) when is_binary(socket_id) do
    socket_id |> String.starts_with?("phx-") |> Kernel.not()
  end

  def nested?(%{socket_id: socket_id}) do
    nested?(socket_id)
  end
end
