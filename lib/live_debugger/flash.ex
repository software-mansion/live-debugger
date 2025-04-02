defmodule LiveDebugger.Flash do
  @moduledoc """
  Functionalities to make flash messages work inside LiveComponents
  See: https://sevenseacat.net/posts/2023/flash-messages-in-phoenix-liveview-components/
  """
  import Phoenix.LiveView

  @doc """
  Attaches hook to handle flash messages
  """
  def on_mount(:add_hook, _params, _session, socket) do
    {:cont, attach_hook(socket, :flash, :handle_info, &maybe_receive_flash/2)}
  end

  @doc """
  Function to put flash inside nested LiveViews/LiveComponents.
  If used in nested LiveView use parent's pid.
  """
  @spec put_flash!(
          socket :: Phoenix.LiveView.Socket.t(),
          message :: String.t()
        ) ::
          Phoenix.LiveView.Socket.t()
  def put_flash!(pid \\ self(), socket, message) do
    send(pid, {:put_flash, message})

    socket
  end

  defp maybe_receive_flash({:put_flash, message}, socket) do
    {:halt, put_flash(socket, :error, message)}
  end

  defp maybe_receive_flash(_, socket), do: {:cont, socket}
end
