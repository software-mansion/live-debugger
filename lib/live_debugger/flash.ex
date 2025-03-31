defmodule LiveDebugger.Flash do
  import Phoenix.LiveView

  @doc """
  Attaches hook to handle flash messages
  """
  def on_mount(:add_hook, _params, _session, socket) do
    {:cont, attach_hook(socket, :flash, :handle_info, &maybe_receive_flash/2)}
  end

  @spec put_flash!(socket :: Phoenix.Socket.t(), type :: :info | :error, message :: String.t()) ::
          Phoenix.Socket.t()
  def put_flash!(socket, type, message) do
    send(self(), {:put_flash, type, message})
    socket
  end

  defp maybe_receive_flash({:put_flash, type, message}, socket) do
    {:halt, put_flash(socket, type, message)}
  end

  defp maybe_receive_flash(_, socket), do: {:cont, socket}
end
